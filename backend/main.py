import os
import json
import random
import sqlite3
from datetime import datetime, timedelta
from contextlib import contextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import anthropic
from dotenv import load_dotenv
import re

load_dotenv()


# =============================================================================
# INPUT SANITIZATION FOR PROMPT INJECTION PREVENTION
# =============================================================================

# Maximum input lengths
MAX_QUERY_LENGTH = 500
MAX_BREAD_NAME_LENGTH = 100

# Patterns that indicate prompt injection attempts
INJECTION_PATTERNS = [
    # Instruction override attempts
    r"(?i)(ignore|disregard|forget|override|bypass)\s+(all\s+)?(previous|above|prior|earlier|system)\s+(instructions?|prompts?|rules?|guidelines?)",
    r"(?i)(new\s+)?instructions?:\s*",
    r"(?i)you\s+are\s+now\s+(a|an)\s+",
    r"(?i)act\s+as\s+(a|an)?\s*(?!bread|baker|baking)",  # Allow "act as a baker"
    r"(?i)pretend\s+(you\s+are|to\s+be)\s+",
    r"(?i)roleplay\s+as\s+",
    r"(?i)switch\s+(to\s+)?(a\s+)?different\s+(mode|persona|role)",
    # System prompt extraction attempts
    r"(?i)(show|reveal|display|print|output|tell\s+me)\s+(your\s+)?(system\s+)?(prompt|instructions?|rules?|guidelines?)",
    r"(?i)what\s+(are\s+)?(your|the)\s+(system\s+)?(instructions?|prompt|rules?)",
    r"(?i)(repeat|echo)\s+(back\s+)?(your\s+)?(system\s+)?(prompt|instructions?)",
    # Delimiter/formatting exploits
    r"```\s*(system|assistant|user)",
    r"<\|?(system|im_start|im_end|endoftext)\|?>",
    r"\[\[?(system|INST|/INST)\]?\]?",
    # Code execution attempts
    r"(?i)(execute|run|eval)\s*(this\s+)?(code|command|script)",
    r"(?i)import\s+os|subprocess|exec\(|eval\(",
]

# Compile patterns for efficiency
COMPILED_INJECTION_PATTERNS = [re.compile(pattern) for pattern in INJECTION_PATTERNS]


def sanitize_input(text: str, max_length: int = MAX_QUERY_LENGTH, field_name: str = "input") -> str:
    """
    Sanitize user input to prevent prompt injection attacks.

    Args:
        text: The user input to sanitize
        max_length: Maximum allowed length for the input
        field_name: Name of the field (for error messages)

    Returns:
        Sanitized text safe for use in prompts

    Raises:
        HTTPException: If input contains obvious injection attempts
    """
    if not text:
        return text

    # Strip whitespace and limit length
    cleaned = text.strip()[:max_length]

    # Remove null bytes and other control characters (except newlines/tabs)
    cleaned = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', '', cleaned)

    # Check for injection patterns
    for pattern in COMPILED_INJECTION_PATTERNS:
        if pattern.search(cleaned):
            raise HTTPException(
                status_code=400,
                detail=f"Invalid {field_name}: contains disallowed content"
            )

    # Normalize excessive whitespace
    cleaned = re.sub(r'\s{3,}', '  ', cleaned)

    return cleaned


def is_bread_related(text: str) -> bool:
    """
    Quick check if input appears to be bread-related.
    Used as an additional layer of validation.
    """
    bread_keywords = [
        'bread', 'bake', 'baking', 'dough', 'flour', 'yeast', 'sourdough',
        'loaf', 'crust', 'crumb', 'knead', 'rise', 'proof', 'oven',
        'recipe', 'ingredient', 'gluten', 'wheat', 'rye', 'starter',
        'ferment', 'leaven', 'ciabatta', 'baguette', 'focaccia', 'brioche',
        'challah', 'naan', 'pita', 'pretzel', 'rolls', 'sandwich'
    ]
    text_lower = text.lower()
    return any(keyword in text_lower for keyword in bread_keywords)

app = FastAPI(title="BreadAI API", version="2.0.0")

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

# Database path
DB_PATH = os.getenv("DATABASE_PATH", "feedback.db")


# =============================================================================
# DATABASE SETUP
# =============================================================================

def init_db():
    """Initialize SQLite database with required tables."""
    with get_db() as conn:
        cursor = conn.cursor()

        # Feedback table for storing user ratings
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS feedback (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                query TEXT NOT NULL,
                response TEXT NOT NULL,
                rating TEXT NOT NULL,
                prompt_variant TEXT NOT NULL,
                response_type TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                user_comment TEXT
            )
        ''')

        # Prompt variants table for A/B testing
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS prompt_variants (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                prompt_text TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        # Analytics cache table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS analytics_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                metric_name TEXT NOT NULL,
                metric_value TEXT NOT NULL,
                computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')

        conn.commit()

        # Insert default prompt variants if none exist
        cursor.execute("SELECT COUNT(*) FROM prompt_variants")
        if cursor.fetchone()[0] == 0:
            default_prompts = [
                ("concise", PROMPT_VARIANTS["concise"]),
                ("detailed", PROMPT_VARIANTS["detailed"]),
                ("friendly", PROMPT_VARIANTS["friendly"]),
            ]
            cursor.executemany(
                "INSERT INTO prompt_variants (name, prompt_text) VALUES (?, ?)",
                default_prompts
            )
            conn.commit()


@contextmanager
def get_db():
    """Context manager for database connections."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


# =============================================================================
# PROMPT VARIANTS FOR A/B TESTING
# =============================================================================

PROMPT_VARIANTS = {
    "concise": """You are a bread expert. Give brief, practical answers about bread.
- Keep responses under 3 sentences when possible
- Focus on actionable advice
- Use simple language
If asked about non-bread topics, redirect to bread.""",

    "detailed": """You are a knowledgeable bread expert and baking instructor. Provide thorough answers about:
- Bread types, techniques, recipes, ingredients, and history
- Include the "why" behind techniques when relevant
- Mention common mistakes to avoid
- Keep responses focused but comprehensive
Redirect non-bread questions back to bread topics.""",

    "friendly": """You are a friendly neighborhood baker who loves sharing bread knowledge! 🍞
- Be warm and encouraging in your responses
- Share personal tips like "I always recommend..."
- Make baking feel approachable and fun
- Celebrate the joy of homemade bread
If asked about non-bread topics, gently steer back to bread with enthusiasm."""
}

def get_active_prompt_variant() -> tuple[str, str]:
    """Get a random active prompt variant for A/B testing."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT name, prompt_text FROM prompt_variants WHERE is_active = 1"
        )
        variants = cursor.fetchall()

    if variants:
        variant = random.choice(variants)
        return variant["name"], variant["prompt_text"]

    # Fallback to default
    return "concise", PROMPT_VARIANTS["concise"]


# =============================================================================
# REQUEST/RESPONSE MODELS
# =============================================================================

class AskRequest(BaseModel):
    query: str


class AskResponse(BaseModel):
    response: str
    response_id: str  # For feedback tracking
    prompt_variant: str  # Which A/B variant was used


class FeedbackRequest(BaseModel):
    response_id: str
    query: str
    response: str
    rating: str  # "positive", "negative", "neutral"
    prompt_variant: str
    response_type: str  # "ask" or "recipe"
    comment: Optional[str] = None


class FeedbackResponse(BaseModel):
    success: bool
    message: str


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
    response_id: str
    prompt_variant: str


class AnalyticsResponse(BaseModel):
    total_feedback: int
    positive_rate: float
    negative_rate: float
    variant_performance: dict
    common_negative_queries: list
    recent_trends: dict


# =============================================================================
# API ENDPOINTS
# =============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize database on startup."""
    init_db()


@app.get("/")
async def root():
    return {"status": "ok", "message": "BreadAI API v2.0 with feedback system"}


@app.get("/health")
async def health():
    return {"status": "healthy", "version": "2.0.0"}


@app.post("/ask", response_model=AskResponse)
async def ask_about_bread(request: AskRequest):
    """Answer bread questions with A/B tested prompts."""
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    # Sanitize input to prevent prompt injection
    sanitized_query = sanitize_input(
        request.query,
        max_length=MAX_QUERY_LENGTH,
        field_name="query"
    )

    # Get A/B test variant
    variant_name, system_prompt = get_active_prompt_variant()

    # Generate unique response ID for feedback tracking
    response_id = f"ask_{datetime.now().strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}"

    try:
        message = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=500,
            system=system_prompt,
            messages=[
                {"role": "user", "content": sanitized_query}
            ]
        )

        response_text = message.content[0].text
        return AskResponse(
            response=response_text,
            response_id=response_id,
            prompt_variant=variant_name
        )

    except anthropic.APIConnectionError:
        raise HTTPException(status_code=503, detail="Unable to connect to AI service")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please try again later.")
    except anthropic.APIStatusError as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


@app.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(request: FeedbackRequest):
    """Store user feedback for prompt optimization."""
    if request.rating not in ["positive", "negative", "neutral"]:
        raise HTTPException(status_code=400, detail="Rating must be 'positive', 'negative', or 'neutral'")

    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO feedback (query, response, rating, prompt_variant, response_type, user_comment)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                request.query,
                request.response,
                request.rating,
                request.prompt_variant,
                request.response_type,
                request.comment
            ))
            conn.commit()

        return FeedbackResponse(success=True, message="Feedback recorded successfully")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to store feedback: {str(e)}")


@app.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics():
    """Get feedback analytics for prompt optimization insights."""
    try:
        with get_db() as conn:
            cursor = conn.cursor()

            # Total feedback count
            cursor.execute("SELECT COUNT(*) FROM feedback")
            total = cursor.fetchone()[0]

            if total == 0:
                return AnalyticsResponse(
                    total_feedback=0,
                    positive_rate=0.0,
                    negative_rate=0.0,
                    variant_performance={},
                    common_negative_queries=[],
                    recent_trends={}
                )

            # Positive/negative rates
            cursor.execute("SELECT COUNT(*) FROM feedback WHERE rating = 'positive'")
            positive = cursor.fetchone()[0]

            cursor.execute("SELECT COUNT(*) FROM feedback WHERE rating = 'negative'")
            negative = cursor.fetchone()[0]

            # Performance by variant
            cursor.execute('''
                SELECT
                    prompt_variant,
                    COUNT(*) as total,
                    SUM(CASE WHEN rating = 'positive' THEN 1 ELSE 0 END) as positive,
                    SUM(CASE WHEN rating = 'negative' THEN 1 ELSE 0 END) as negative
                FROM feedback
                GROUP BY prompt_variant
            ''')

            variant_performance = {}
            for row in cursor.fetchall():
                variant_total = row["total"]
                variant_performance[row["prompt_variant"]] = {
                    "total": variant_total,
                    "positive_rate": round(row["positive"] / variant_total * 100, 1) if variant_total > 0 else 0,
                    "negative_rate": round(row["negative"] / variant_total * 100, 1) if variant_total > 0 else 0
                }

            # Common negative queries (to identify problem areas)
            cursor.execute('''
                SELECT query, COUNT(*) as count
                FROM feedback
                WHERE rating = 'negative'
                GROUP BY query
                ORDER BY count DESC
                LIMIT 10
            ''')
            common_negative = [{"query": row["query"], "count": row["count"]} for row in cursor.fetchall()]

            # Recent trends (last 7 days vs previous 7 days)
            cursor.execute('''
                SELECT
                    SUM(CASE WHEN rating = 'positive' THEN 1 ELSE 0 END) as positive,
                    COUNT(*) as total
                FROM feedback
                WHERE created_at >= datetime('now', '-7 days')
            ''')
            recent = cursor.fetchone()
            recent_rate = round(recent["positive"] / recent["total"] * 100, 1) if recent["total"] > 0 else 0

            cursor.execute('''
                SELECT
                    SUM(CASE WHEN rating = 'positive' THEN 1 ELSE 0 END) as positive,
                    COUNT(*) as total
                FROM feedback
                WHERE created_at >= datetime('now', '-14 days')
                AND created_at < datetime('now', '-7 days')
            ''')
            previous = cursor.fetchone()
            previous_rate = round(previous["positive"] / previous["total"] * 100, 1) if previous["total"] > 0 else 0

            return AnalyticsResponse(
                total_feedback=total,
                positive_rate=round(positive / total * 100, 1),
                negative_rate=round(negative / total * 100, 1),
                variant_performance=variant_performance,
                common_negative_queries=common_negative,
                recent_trends={
                    "last_7_days_positive_rate": recent_rate,
                    "previous_7_days_positive_rate": previous_rate,
                    "trend": "improving" if recent_rate > previous_rate else "declining" if recent_rate < previous_rate else "stable"
                }
            )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to compute analytics: {str(e)}")


@app.get("/prompts")
async def get_prompt_variants():
    """Get all prompt variants and their status."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT name, is_active, created_at FROM prompt_variants")
        variants = [dict(row) for row in cursor.fetchall()]
    return {"variants": variants}


@app.post("/prompts/{variant_name}/toggle")
async def toggle_prompt_variant(variant_name: str):
    """Enable/disable a prompt variant for A/B testing."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE prompt_variants SET is_active = NOT is_active WHERE name = ?",
            (variant_name,)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Variant not found")
        conn.commit()

    return {"success": True, "message": f"Toggled variant: {variant_name}"}


@app.post("/prompts/add")
async def add_prompt_variant(name: str, prompt_text: str):
    """Add a new prompt variant for testing."""
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO prompt_variants (name, prompt_text) VALUES (?, ?)",
                (name, prompt_text)
            )
            conn.commit()
        return {"success": True, "message": f"Added variant: {name}"}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Variant name already exists")


# =============================================================================
# RECIPE ENDPOINT (with feedback tracking)
# =============================================================================

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
    """Generate a bread recipe with feedback tracking."""
    if not request.bread_name.strip():
        raise HTTPException(status_code=400, detail="Bread name cannot be empty")

    # Sanitize input to prevent prompt injection
    sanitized_bread_name = sanitize_input(
        request.bread_name,
        max_length=MAX_BREAD_NAME_LENGTH,
        field_name="bread_name"
    )

    response_id = f"recipe_{datetime.now().strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}"
    variant_name = "recipe_default"

    try:
        message = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=1500,
            messages=[
                {"role": "user", "content": RECIPE_PROMPT.format(bread_name=sanitized_bread_name)}
            ]
        )

        response_text = message.content[0].text.strip()

        # Parse JSON response
        import re
        try:
            recipe_data = json.loads(response_text)
        except json.JSONDecodeError:
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
            tips=recipe_data.get("tips", "Enjoy your fresh bread!"),
            response_id=response_id,
            prompt_variant=variant_name
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
