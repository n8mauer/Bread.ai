import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import anthropic
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="BreadAI API", version="1.0.0")

# CORS middleware for iOS app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Anthropic client
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

SYSTEM_PROMPT = """You are a friendly and knowledgeable bread expert. You answer questions about:
- Different types of bread (sourdough, rye, baguettes, etc.)
- Baking techniques and tips
- Bread recipes and ingredients
- The history and culture of bread around the world
- Gluten-free and dietary alternatives

Keep your answers concise, helpful, and focused on bread-related topics. If asked about something unrelated to bread, politely redirect the conversation back to bread."""


class AskRequest(BaseModel):
    query: str


class AskResponse(BaseModel):
    response: str


class RecipeRequest(BaseModel):
    bread_name: str


class RecipeResponse(BaseModel):
    name: str
    description: str
    prep_time: str
    ferment_time: str
    bake_time: str
    difficulty: str
    ingredients: list[dict]
    instructions: list[str]
    tips: str


@app.get("/")
async def root():
    return {"status": "ok", "message": "BreadAI API is running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.post("/ask", response_model=AskResponse)
async def ask_about_bread(request: AskRequest):
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    try:
        message = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=500,
            system=SYSTEM_PROMPT,
            messages=[
                {"role": "user", "content": request.query}
            ]
        )

        response_text = message.content[0].text
        return AskResponse(response=response_text)

    except anthropic.APIConnectionError:
        raise HTTPException(status_code=503, detail="Unable to connect to AI service")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please try again later.")
    except anthropic.APIStatusError as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


RECIPE_PROMPT = """Generate a complete bread recipe for {bread_name}.

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
    "name": "{bread_name}",
    "description": "A brief 1-sentence description of this bread",
    "prep_time": "X min",
    "ferment_time": "X hrs" or "N/A" if no fermentation,
    "bake_time": "X min",
    "difficulty": "Easy" or "Medium" or "Hard",
    "ingredients": [
        {{"amount": "500g", "item": "bread flour"}},
        {{"amount": "10g", "item": "salt"}}
    ],
    "instructions": [
        "Step 1 description",
        "Step 2 description"
    ],
    "tips": "A helpful baker's tip for this specific bread"
}}

Be accurate with traditional recipes. Include 6-10 ingredients and 6-10 clear steps."""


@app.post("/recipe", response_model=RecipeResponse)
async def generate_recipe(request: RecipeRequest):
    if not request.bread_name.strip():
        raise HTTPException(status_code=400, detail="Bread name cannot be empty")

    try:
        message = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=1500,
            messages=[
                {"role": "user", "content": RECIPE_PROMPT.format(bread_name=request.bread_name)}
            ]
        )

        response_text = message.content[0].text.strip()

        # Parse JSON response
        import json
        try:
            recipe_data = json.loads(response_text)
        except json.JSONDecodeError:
            # Try to extract JSON if wrapped in markdown
            import re
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                recipe_data = json.loads(json_match.group())
            else:
                raise HTTPException(status_code=500, detail="Failed to parse recipe")

        return RecipeResponse(
            name=recipe_data.get("name", request.bread_name),
            description=recipe_data.get("description", "A delicious homemade bread"),
            prep_time=recipe_data.get("prep_time", "30 min"),
            ferment_time=recipe_data.get("ferment_time", "N/A"),
            bake_time=recipe_data.get("bake_time", "45 min"),
            difficulty=recipe_data.get("difficulty", "Medium"),
            ingredients=recipe_data.get("ingredients", []),
            instructions=recipe_data.get("instructions", []),
            tips=recipe_data.get("tips", "Enjoy your fresh bread!")
        )

    except anthropic.APIConnectionError:
        raise HTTPException(status_code=503, detail="Unable to connect to AI service")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please try again later.")
    except anthropic.APIStatusError as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
