"""
Unit tests for BreadAI FastAPI backend.
Tests cover API endpoints, validation, error handling, and JSON parsing.
"""

import json
import pytest
from unittest.mock import Mock, patch, MagicMock
from fastapi.testclient import TestClient
import anthropic

# Import the FastAPI app
from main import app, AskRequest, RecipeRequest, RecipeResponse


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    return TestClient(app)


class TestHealthEndpoints:
    """Tests for health check endpoints."""

    def test_root_endpoint(self, client):
        """Test the root endpoint returns correct status."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "BreadAI API is running" in data["message"]

    def test_health_endpoint(self, client):
        """Test the health endpoint returns healthy status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"


class TestAskEndpoint:
    """Tests for the /ask endpoint."""

    def test_ask_empty_query_returns_400(self, client):
        """Test that an empty query returns a 400 error."""
        response = client.post("/ask", json={"query": ""})
        assert response.status_code == 400
        assert "Query cannot be empty" in response.json()["detail"]

    def test_ask_whitespace_query_returns_400(self, client):
        """Test that a whitespace-only query returns a 400 error."""
        response = client.post("/ask", json={"query": "   "})
        assert response.status_code == 400
        assert "Query cannot be empty" in response.json()["detail"]

    def test_ask_missing_query_returns_422(self, client):
        """Test that a missing query field returns a 422 validation error."""
        response = client.post("/ask", json={})
        assert response.status_code == 422

    @patch("main.client")
    def test_ask_valid_query_returns_response(self, mock_anthropic_client, client):
        """Test that a valid query returns an AI response."""
        # Mock the Anthropic response
        mock_message = Mock()
        mock_message.content = [Mock(text="Sourdough is a naturally leavened bread.")]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/ask", json={"query": "What is sourdough?"})

        assert response.status_code == 200
        data = response.json()
        assert "response" in data
        assert "Sourdough" in data["response"]

    @patch("main.client")
    def test_ask_api_connection_error_returns_503(self, mock_anthropic_client, client):
        """Test that API connection errors return 503."""
        mock_anthropic_client.messages.create.side_effect = anthropic.APIConnectionError(
            request=Mock()
        )

        response = client.post("/ask", json={"query": "What is bread?"})

        assert response.status_code == 503
        assert "Unable to connect" in response.json()["detail"]

    @patch("main.client")
    def test_ask_rate_limit_error_returns_429(self, mock_anthropic_client, client):
        """Test that rate limit errors return 429."""
        mock_response = Mock()
        mock_response.status_code = 429
        mock_anthropic_client.messages.create.side_effect = anthropic.RateLimitError(
            message="Rate limit exceeded",
            response=mock_response,
            body={}
        )

        response = client.post("/ask", json={"query": "What is bread?"})

        assert response.status_code == 429
        assert "Rate limit" in response.json()["detail"]


class TestRecipeEndpoint:
    """Tests for the /recipe endpoint."""

    def test_recipe_empty_bread_name_returns_400(self, client):
        """Test that an empty bread name returns a 400 error."""
        response = client.post("/recipe", json={"bread_name": ""})
        assert response.status_code == 400
        assert "Bread name cannot be empty" in response.json()["detail"]

    def test_recipe_whitespace_bread_name_returns_400(self, client):
        """Test that a whitespace-only bread name returns a 400 error."""
        response = client.post("/recipe", json={"bread_name": "   "})
        assert response.status_code == 400
        assert "Bread name cannot be empty" in response.json()["detail"]

    def test_recipe_missing_bread_name_returns_422(self, client):
        """Test that a missing bread_name field returns a 422 validation error."""
        response = client.post("/recipe", json={})
        assert response.status_code == 422

    @patch("main.client")
    def test_recipe_valid_request_returns_recipe(self, mock_anthropic_client, client):
        """Test that a valid recipe request returns a complete recipe."""
        # Mock a valid JSON recipe response
        recipe_json = json.dumps({
            "name": "Ciabatta",
            "description": "A classic Italian bread with a crispy crust and airy interior.",
            "prep_time": "30 min",
            "ferment_time": "2 hrs",
            "bake_time": "25 min",
            "difficulty": "Medium",
            "ingredients": [
                {"amount": "500g", "item": "bread flour"},
                {"amount": "350ml", "item": "water"},
                {"amount": "10g", "item": "salt"},
                {"amount": "7g", "item": "instant yeast"},
                {"amount": "2 tbsp", "item": "olive oil"}
            ],
            "instructions": [
                "Mix flour, water, yeast, and let rest 20 minutes.",
                "Add salt and olive oil, mix thoroughly.",
                "Let rise for 2 hours with folds every 30 minutes.",
                "Shape gently and proof for 45 minutes.",
                "Bake at 450°F for 25 minutes."
            ],
            "tips": "Handle the dough gently to preserve the air bubbles."
        })

        mock_message = Mock()
        mock_message.content = [Mock(text=recipe_json)]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/recipe", json={"bread_name": "Ciabatta"})

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Ciabatta"
        assert "description" in data
        assert "prep_time" in data
        assert "ferment_time" in data
        assert "bake_time" in data
        assert "difficulty" in data
        assert isinstance(data["ingredients"], list)
        assert isinstance(data["instructions"], list)
        assert "tips" in data

    @patch("main.client")
    def test_recipe_handles_markdown_wrapped_json(self, mock_anthropic_client, client):
        """Test that recipe endpoint can handle JSON wrapped in markdown code blocks."""
        # Sometimes LLMs wrap JSON in markdown code blocks
        recipe_json = '''```json
{
    "name": "Focaccia",
    "description": "Italian flatbread with olive oil.",
    "prep_time": "20 min",
    "ferment_time": "1 hr",
    "bake_time": "20 min",
    "difficulty": "Easy",
    "ingredients": [{"amount": "500g", "item": "flour"}],
    "instructions": ["Mix and bake."],
    "tips": "Use good olive oil."
}
```'''

        mock_message = Mock()
        mock_message.content = [Mock(text=recipe_json)]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/recipe", json={"bread_name": "Focaccia"})

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Focaccia"

    @patch("main.client")
    def test_recipe_handles_missing_fields_with_defaults(self, mock_anthropic_client, client):
        """Test that missing recipe fields are filled with defaults."""
        # Minimal JSON response missing some fields
        recipe_json = json.dumps({
            "name": "Simple Bread",
            "ingredients": [{"amount": "500g", "item": "flour"}],
            "instructions": ["Mix and bake."]
        })

        mock_message = Mock()
        mock_message.content = [Mock(text=recipe_json)]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/recipe", json={"bread_name": "Simple Bread"})

        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Simple Bread"
        # Check defaults are applied
        assert data["description"] == "A delicious homemade bread"
        assert data["prep_time"] == "30 min"
        assert data["ferment_time"] == "N/A"
        assert data["bake_time"] == "45 min"
        assert data["difficulty"] == "Medium"

    @patch("main.client")
    def test_recipe_api_connection_error_returns_503(self, mock_anthropic_client, client):
        """Test that API connection errors return 503."""
        mock_anthropic_client.messages.create.side_effect = anthropic.APIConnectionError(
            request=Mock()
        )

        response = client.post("/recipe", json={"bread_name": "Baguette"})

        assert response.status_code == 503
        assert "Unable to connect" in response.json()["detail"]

    @patch("main.client")
    def test_recipe_invalid_json_returns_500(self, mock_anthropic_client, client):
        """Test that invalid JSON response returns 500."""
        mock_message = Mock()
        mock_message.content = [Mock(text="This is not JSON at all")]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/recipe", json={"bread_name": "Test Bread"})

        assert response.status_code == 500
        assert "Failed to parse recipe" in response.json()["detail"]


class TestRequestModels:
    """Tests for Pydantic request/response models."""

    def test_ask_request_model_valid(self):
        """Test AskRequest model with valid data."""
        request = AskRequest(query="What is bread?")
        assert request.query == "What is bread?"

    def test_recipe_request_model_valid(self):
        """Test RecipeRequest model with valid data."""
        request = RecipeRequest(bread_name="Sourdough")
        assert request.bread_name == "Sourdough"

    def test_recipe_response_model_valid(self):
        """Test RecipeResponse model with valid data."""
        response = RecipeResponse(
            name="Test Bread",
            description="A test bread",
            prep_time="10 min",
            ferment_time="1 hr",
            bake_time="30 min",
            difficulty="Easy",
            ingredients=[{"amount": "500g", "item": "flour"}],
            instructions=["Step 1", "Step 2"],
            tips="Test tip"
        )
        assert response.name == "Test Bread"
        assert len(response.ingredients) == 1
        assert len(response.instructions) == 2


class TestEdgeCases:
    """Tests for edge cases and boundary conditions."""

    @patch("main.client")
    def test_ask_with_special_characters(self, mock_anthropic_client, client):
        """Test query with special characters."""
        mock_message = Mock()
        mock_message.content = [Mock(text="Special chars handled.")]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/ask", json={"query": "What's the best bread? It's <great>!"})

        assert response.status_code == 200

    @patch("main.client")
    def test_ask_with_unicode(self, mock_anthropic_client, client):
        """Test query with unicode characters."""
        mock_message = Mock()
        mock_message.content = [Mock(text="Pain français explained.")]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/ask", json={"query": "Tell me about pain français 🍞"})

        assert response.status_code == 200

    @patch("main.client")
    def test_recipe_with_long_bread_name(self, mock_anthropic_client, client):
        """Test recipe with a very long bread name."""
        recipe_json = json.dumps({
            "name": "A" * 100,
            "description": "Test",
            "prep_time": "10 min",
            "ferment_time": "N/A",
            "bake_time": "30 min",
            "difficulty": "Easy",
            "ingredients": [{"amount": "500g", "item": "flour"}],
            "instructions": ["Bake it."],
            "tips": "Tip"
        })

        mock_message = Mock()
        mock_message.content = [Mock(text=recipe_json)]
        mock_anthropic_client.messages.create.return_value = mock_message

        response = client.post("/recipe", json={"bread_name": "A" * 100})

        assert response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
