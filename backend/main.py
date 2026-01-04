import os
import json
import random
import sqlite3
import hashlib
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
# CACHE CONFIGURATION
# =============================================================================

# Cache TTL (time-to-live) in seconds
CACHE_TTL_ASK = int(os.getenv("CACHE_TTL_ASK", 3600))  # 1 hour for Q&A
CACHE_TTL_RECIPE = int(os.getenv("CACHE_TTL_RECIPE", 86400))  # 24 hours for recipes
CACHE_ENABLED = os.getenv("CACHE_ENABLED", "true").lower() == "true"


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
    r"(?i)(ignore|disregard|forget|override|bypass)\s+(your\s+)?(system\s+)?(instructions?|prompts?|rules?|guidelines?)",
    r"(?i)(new\s+)?instructions?:\s*",
    r"(?i)you\s+are\s+now\s+(a|an)\s+",
    r"(?i)pretend\s+(you\s+are|to\s+be)\s+",
    r"(?i)roleplay\s+as\s+",
    r"(?i)switch\s+(to\s+)?(a\s+)?different\s+(mode|persona|role)",
    # System prompt extraction attempts
    r"(?i)(show|reveal|display|print|output)\s+(me\s+)?(your\s+)?(system\s+)?(prompt|instructions?|rules?|guidelines?)",
    r"(?i)tell\s+me\s+(your\s+)?(system\s+)?(prompt|instructions?|rules?|guidelines?)",
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

        # Response cache table for reducing API costs
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS response_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cache_key TEXT UNIQUE NOT NULL,
                cache_type TEXT NOT NULL,
                query TEXT NOT NULL,
                response_data TEXT NOT NULL,
                prompt_variant TEXT,
                hit_count INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP NOT NULL
            )
        ''')

        # Create index for faster cache lookups
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_cache_key ON response_cache(cache_key)
        ''')
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_cache_expires ON response_cache(expires_at)
        ''')

        # Challenges table for tracking user completions
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS challenge_completions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                challenge_id TEXT NOT NULL,
                week_number INTEGER NOT NULL,
                points_awarded INTEGER NOT NULL,
                completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, challenge_id, week_number)
            )
        ''')

        # Tips table for baking tips
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tips (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT NOT NULL,
                tip_text TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

        # Insert default tips if none exist
        cursor.execute("SELECT COUNT(*) FROM tips")
        if cursor.fetchone()[0] == 0:
            default_tips = [
                ("proofing", "For optimal proofing, aim for 75-80°F (24-27°C). Your dough should roughly double in size."),
                ("proofing", "The poke test: gently press your finger into the dough. If it springs back slowly, it's ready."),
                ("proofing", "Over-proofed dough will deflate when touched. Under-proofed will spring back immediately."),
                ("kneading", "Knead for 8-10 minutes until the dough is smooth and elastic. The windowpane test shows proper gluten development."),
                ("kneading", "Don't add too much flour while kneading. The dough should be slightly tacky, not dry."),
                ("kneading", "For no-knead breads, time and folding replace traditional kneading to develop gluten."),
                ("shaping", "Shape with purpose and tension. A tight surface creates better oven spring."),
                ("shaping", "Let shaped dough rest 15-20 minutes before final shaping to relax the gluten."),
                ("shaping", "Flour your work surface lightly. Too much flour makes it hard to create tension."),
                ("baking", "Preheat your oven for at least 30 minutes. A properly heated oven is crucial for good oven spring."),
                ("baking", "Steam in the first 10-15 minutes creates a crispy crust. Use a pan of water or spray bottle."),
                ("baking", "Internal temperature of 190-210°F (88-99°C) indicates bread is fully baked."),
                ("baking", "Let bread cool completely before slicing. It's still cooking inside as it cools."),
                ("general", "Measure by weight, not volume, for consistent results every time."),
                ("general", "Water temperature matters: too hot kills yeast, too cold slows it down. Aim for 100-110°F (38-43°C)."),
                ("general", "Salt controls fermentation speed and strengthens gluten. Don't skip it or add it directly to yeast."),
                ("general", "Fresh yeast makes a difference. Check the expiration date and store properly."),
            ]
            cursor.executemany(
                "INSERT INTO tips (category, tip_text) VALUES (?, ?)",
                default_tips
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
# CACHING FUNCTIONS
# =============================================================================

def generate_cache_key(query: str, cache_type: str) -> str:
    """Generate a unique cache key for a query."""
    normalized = ' '.join(query.lower().strip().split())
    key_string = f"{cache_type}:{normalized}"
    return hashlib.sha256(key_string.encode()).hexdigest()[:32]


def get_cached_response(cache_key: str) -> Optional[dict]:
    """Retrieve a cached response if it exists and hasn't expired."""
    if not CACHE_ENABLED:
        return None

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT response_data, prompt_variant, hit_count
            FROM response_cache
            WHERE cache_key = ? AND expires_at > datetime('now')
        ''', (cache_key,))
        row = cursor.fetchone()

        if row:
            cursor.execute('''
                UPDATE response_cache SET hit_count = hit_count + 1
                WHERE cache_key = ?
            ''', (cache_key,))
            conn.commit()

            return {
                "response_data": json.loads(row["response_data"]),
                "prompt_variant": row["prompt_variant"],
                "hit_count": row["hit_count"] + 1,
                "cached": True
            }

    return None


def cache_response(
    cache_key: str,
    cache_type: str,
    query: str,
    response_data: dict,
    prompt_variant: str,
    ttl_seconds: int
) -> bool:
    """Store a response in the cache."""
    if not CACHE_ENABLED:
        return False

    try:
        with get_db() as conn:
            cursor = conn.cursor()
            expires_at = datetime.now() + timedelta(seconds=ttl_seconds)

            cursor.execute('''
                INSERT OR REPLACE INTO response_cache
                (cache_key, cache_type, query, response_data, prompt_variant, hit_count, expires_at)
                VALUES (?, ?, ?, ?, ?, 0, ?)
            ''', (
                cache_key,
                cache_type,
                query,
                json.dumps(response_data),
                prompt_variant,
                expires_at.isoformat()
            ))
            conn.commit()
            return True
    except Exception as e:
        print(f"Cache write error: {e}")
        return False


def cleanup_expired_cache() -> int:
    """Remove expired cache entries."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM response_cache WHERE expires_at < datetime('now')")
        deleted = cursor.rowcount
        conn.commit()
        return deleted


def clear_all_cache() -> int:
    """Clear all cache entries."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM response_cache")
        deleted = cursor.rowcount
        conn.commit()
        return deleted


def get_cache_stats() -> dict:
    """Get cache statistics."""
    with get_db() as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT COUNT(*) FROM response_cache")
        total_entries = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM response_cache WHERE expires_at > datetime('now')")
        active_entries = cursor.fetchone()[0]

        cursor.execute("SELECT COALESCE(SUM(hit_count), 0) FROM response_cache")
        total_hits = cursor.fetchone()[0]

        cursor.execute('''
            SELECT cache_type, COUNT(*) as count, COALESCE(SUM(hit_count), 0) as hits
            FROM response_cache
            WHERE expires_at > datetime('now')
            GROUP BY cache_type
        ''')
        by_type = {row["cache_type"]: {"count": row["count"], "hits": row["hits"]}
                   for row in cursor.fetchall()}

        cursor.execute('''
            SELECT query, hit_count, cache_type
            FROM response_cache
            WHERE expires_at > datetime('now')
            ORDER BY hit_count DESC
            LIMIT 10
        ''')
        top_queries = [{"query": row["query"][:50], "hits": row["hit_count"], "type": row["cache_type"]}
                       for row in cursor.fetchall()]

        # Estimated savings: ~$0.0003 per Haiku request
        estimated_savings = round(total_hits * 0.0003, 4)

        return {
            "enabled": CACHE_ENABLED,
            "total_entries": total_entries,
            "active_entries": active_entries,
            "expired_entries": total_entries - active_entries,
            "total_cache_hits": total_hits,
            "by_type": by_type,
            "top_cached_queries": top_queries,
            "estimated_savings_usd": estimated_savings,
            "ttl_ask_seconds": CACHE_TTL_ASK,
            "ttl_recipe_seconds": CACHE_TTL_RECIPE
        }


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
    cached: bool = False  # Whether response was served from cache


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
    cached: bool = False


class AnalyticsResponse(BaseModel):
    total_feedback: int
    positive_rate: float
    negative_rate: float
    variant_performance: dict
    common_negative_queries: list
    recent_trends: dict


# =============================================================================
# WEEKLY CHALLENGES
# =============================================================================

WEEKLY_CHALLENGES = [
    {
        "id": "bake_3",
        "title": "Triple Threat",
        "description": "Bake 3 loaves this week",
        "points_reward": 150,
        "difficulty": "medium"
    },
    {
        "id": "try_new",
        "title": "Explorer",
        "description": "Try a bread you've never made",
        "points_reward": 100,
        "difficulty": "medium"
    },
    {
        "id": "weekend_bake",
        "title": "Weekend Baker",
        "description": "Bake on Saturday or Sunday",
        "points_reward": 75,
        "difficulty": "easy"
    },
    {
        "id": "share_photo",
        "title": "Show Off",
        "description": "Share your bake on social media",
        "points_reward": 50,
        "difficulty": "easy"
    },
    {
        "id": "sourdough_start",
        "title": "Sourdough Starter",
        "description": "Feed your starter every day this week",
        "points_reward": 100,
        "difficulty": "medium"
    },
    {
        "id": "early_bird",
        "title": "Early Bird Baker",
        "description": "Bake before 9 AM",
        "points_reward": 75,
        "difficulty": "easy"
    },
]


class Challenge(BaseModel):
    id: str
    title: str
    description: str
    points_reward: int
    difficulty: str
    expires_at: str


class ChallengeCompletionRequest(BaseModel):
    user_id: str = "default_user"  # For MVP, using default user


class ChallengeCompletionResponse(BaseModel):
    success: bool
    points_awarded: int
    message: str


class TipResponse(BaseModel):
    category: str
    tip: str


class TechniqueRequest(BaseModel):
    technique: str


class TechniqueResponse(BaseModel):
    technique: str
    explanation: str
    why_used: str
    how_to: str
    common_mistakes: list[str]
    cached: bool = False


class TroubleshootRequest(BaseModel):
    problem: str


class TroubleshootResponse(BaseModel):
    problem: str
    likely_causes: list[str]
    solutions: list[str]
    prevention_tips: list[str]


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
    """Answer bread questions with A/B tested prompts and caching."""
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty")

    # Sanitize input to prevent prompt injection
    sanitized_query = sanitize_input(
        request.query,
        max_length=MAX_QUERY_LENGTH,
        field_name="query"
    )

    # Check cache first
    cache_key = generate_cache_key(sanitized_query, "ask")
    cached = get_cached_response(cache_key)

    if cached:
        response_id = f"ask_cached_{datetime.now().strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}"
        return AskResponse(
            response=cached["response_data"]["response"],
            response_id=response_id,
            prompt_variant=cached["prompt_variant"],
            cached=True
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

        # Cache the response
        cache_response(
            cache_key=cache_key,
            cache_type="ask",
            query=sanitized_query,
            response_data={"response": response_text},
            prompt_variant=variant_name,
            ttl_seconds=CACHE_TTL_ASK
        )

        return AskResponse(
            response=response_text,
            response_id=response_id,
            prompt_variant=variant_name,
            cached=False
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
    """Generate a bread recipe with caching and feedback tracking."""
    if not request.bread_name.strip():
        raise HTTPException(status_code=400, detail="Bread name cannot be empty")

    # Sanitize input to prevent prompt injection
    sanitized_bread_name = sanitize_input(
        request.bread_name,
        max_length=MAX_BREAD_NAME_LENGTH,
        field_name="bread_name"
    )

    # Check cache first
    cache_key = generate_cache_key(sanitized_bread_name, "recipe")
    cached = get_cached_response(cache_key)

    if cached:
        recipe_data = cached["response_data"]
        response_id = f"recipe_cached_{datetime.now().strftime('%Y%m%d%H%M%S')}_{random.randint(1000, 9999)}"
        return RecipeResponse(
            name=recipe_data.get("name", sanitized_bread_name),
            description=recipe_data.get("description", "A delicious homemade bread"),
            prep_time=recipe_data.get("prep_time", "30 min"),
            ferment_time=recipe_data.get("ferment_time", "N/A"),
            bake_time=recipe_data.get("bake_time", "45 min"),
            difficulty=recipe_data.get("difficulty", "Medium"),
            ingredients=recipe_data.get("ingredients", []),
            instructions=recipe_data.get("instructions", []),
            tips=recipe_data.get("tips", "Enjoy your fresh bread!"),
            response_id=response_id,
            prompt_variant=cached["prompt_variant"],
            cached=True
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
        try:
            recipe_data = json.loads(response_text)
        except json.JSONDecodeError:
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                recipe_data = json.loads(json_match.group())
            else:
                raise HTTPException(status_code=500, detail="Failed to parse recipe")

        # Cache the recipe
        cache_response(
            cache_key=cache_key,
            cache_type="recipe",
            query=sanitized_bread_name,
            response_data=recipe_data,
            prompt_variant=variant_name,
            ttl_seconds=CACHE_TTL_RECIPE
        )

        return RecipeResponse(
            name=recipe_data.get("name", sanitized_bread_name),
            description=recipe_data.get("description", "A delicious homemade bread"),
            prep_time=recipe_data.get("prep_time", "30 min"),
            ferment_time=recipe_data.get("ferment_time", "N/A"),
            bake_time=recipe_data.get("bake_time", "45 min"),
            difficulty=recipe_data.get("difficulty", "Medium"),
            ingredients=recipe_data.get("ingredients", []),
            instructions=recipe_data.get("instructions", []),
            tips=recipe_data.get("tips", "Enjoy your fresh bread!"),
            response_id=response_id,
            prompt_variant=variant_name,
            cached=False
        )

    except anthropic.APIConnectionError:
        raise HTTPException(status_code=503, detail="Unable to connect to AI service")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please try again later.")
    except anthropic.APIStatusError as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


# =============================================================================
# CACHE MANAGEMENT ENDPOINTS
# =============================================================================

@app.get("/cache/stats")
async def cache_statistics():
    """Get cache statistics and performance metrics."""
    return get_cache_stats()


@app.post("/cache/cleanup")
async def cache_cleanup():
    """Remove expired cache entries."""
    deleted = cleanup_expired_cache()
    return {"success": True, "deleted_entries": deleted}


@app.post("/cache/clear")
async def cache_clear():
    """Clear all cache entries (use with caution)."""
    deleted = clear_all_cache()
    return {"success": True, "deleted_entries": deleted}


# =============================================================================
# WEEKLY CHALLENGES ENDPOINTS
# =============================================================================

def get_current_week_number() -> int:
    """Get ISO week number for challenge rotation."""
    return datetime.now().isocalendar()[1]


def get_week_end_date() -> str:
    """Get end of current week in ISO format."""
    now = datetime.now()
    days_until_sunday = (6 - now.weekday()) % 7
    end_of_week = now + timedelta(days=days_until_sunday)
    return end_of_week.replace(hour=23, minute=59, second=59).isoformat()


@app.get("/challenges")
async def get_challenges():
    """Get current weekly challenges with expiration time."""
    week_number = get_current_week_number()
    expires_at = get_week_end_date()

    # Rotate challenges based on week number
    # This ensures different challenges appear each week
    num_challenges = len(WEEKLY_CHALLENGES)
    rotation_offset = week_number % num_challenges

    # Select 4 challenges for this week
    selected_challenges = []
    for i in range(4):
        challenge_index = (rotation_offset + i) % num_challenges
        challenge = WEEKLY_CHALLENGES[challenge_index].copy()
        challenge["expires_at"] = expires_at
        selected_challenges.append(Challenge(**challenge))

    return {"challenges": selected_challenges, "week_number": week_number}


@app.post("/challenges/{challenge_id}/complete", response_model=ChallengeCompletionResponse)
async def complete_challenge(challenge_id: str, request: ChallengeCompletionRequest):
    """Mark a challenge as completed and award points."""
    # Find the challenge
    challenge = next((c for c in WEEKLY_CHALLENGES if c["id"] == challenge_id), None)
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")

    week_number = get_current_week_number()
    user_id = request.user_id

    try:
        with get_db() as conn:
            cursor = conn.cursor()

            # Check if already completed this week
            cursor.execute('''
                SELECT id FROM challenge_completions
                WHERE user_id = ? AND challenge_id = ? AND week_number = ?
            ''', (user_id, challenge_id, week_number))

            if cursor.fetchone():
                return ChallengeCompletionResponse(
                    success=False,
                    points_awarded=0,
                    message="Challenge already completed this week"
                )

            # Record completion
            cursor.execute('''
                INSERT INTO challenge_completions (user_id, challenge_id, week_number, points_awarded)
                VALUES (?, ?, ?, ?)
            ''', (user_id, challenge_id, week_number, challenge["points_reward"]))

            conn.commit()

            return ChallengeCompletionResponse(
                success=True,
                points_awarded=challenge["points_reward"],
                message=f"Challenge completed! You earned {challenge['points_reward']} points!"
            )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to complete challenge: {str(e)}")


# =============================================================================
# BAKING TIPS ENDPOINTS
# =============================================================================

@app.get("/tips", response_model=TipResponse)
async def get_random_tip(category: Optional[str] = None):
    """Get a random baking tip, optionally filtered by category."""
    try:
        with get_db() as conn:
            cursor = conn.cursor()

            if category:
                # Validate category
                valid_categories = ["proofing", "kneading", "shaping", "baking", "general"]
                if category not in valid_categories:
                    raise HTTPException(
                        status_code=400,
                        detail=f"Invalid category. Must be one of: {', '.join(valid_categories)}"
                    )

                cursor.execute('''
                    SELECT category, tip_text FROM tips
                    WHERE category = ?
                    ORDER BY RANDOM()
                    LIMIT 1
                ''', (category,))
            else:
                cursor.execute('''
                    SELECT category, tip_text FROM tips
                    ORDER BY RANDOM()
                    LIMIT 1
                ''')

            row = cursor.fetchone()
            if not row:
                raise HTTPException(status_code=404, detail="No tips found")

            return TipResponse(category=row["category"], tip=row["tip_text"])

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve tip: {str(e)}")


@app.get("/tips/daily", response_model=TipResponse)
async def get_daily_tip():
    """Get tip-of-the-day (consistent for 24 hours based on date hash)."""
    try:
        with get_db() as conn:
            cursor = conn.cursor()

            # Get total number of tips
            cursor.execute("SELECT COUNT(*) FROM tips")
            total_tips = cursor.fetchone()[0]

            if total_tips == 0:
                raise HTTPException(status_code=404, detail="No tips available")

            # Use date hash to select consistent tip for the day
            today = datetime.now().strftime("%Y-%m-%d")
            date_hash = int(hashlib.sha256(today.encode()).hexdigest(), 16)
            tip_index = date_hash % total_tips

            cursor.execute('''
                SELECT category, tip_text FROM tips
                LIMIT 1 OFFSET ?
            ''', (tip_index,))

            row = cursor.fetchone()
            return TipResponse(category=row["category"], tip=row["tip_text"])

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve daily tip: {str(e)}")


# =============================================================================
# TECHNIQUE EXPLANATION ENDPOINT
# =============================================================================

TECHNIQUE_PROMPT = """Explain the bread baking technique: {technique}

Provide a detailed, structured explanation covering:
1. What it is (brief definition)
2. Why it's used (benefits and purpose)
3. How to do it (step-by-step)
4. Common mistakes to avoid

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
    "technique": "{technique}",
    "explanation": "A clear 2-3 sentence explanation of what this technique is",
    "why_used": "1-2 sentences explaining the purpose and benefits",
    "how_to": "Step-by-step instructions in a single paragraph",
    "common_mistakes": [
        "First common mistake to avoid",
        "Second common mistake to avoid",
        "Third common mistake to avoid"
    ]
}}

Be accurate and practical. Focus on actionable information."""


@app.post("/technique", response_model=TechniqueResponse)
async def explain_technique(request: TechniqueRequest):
    """Get detailed explanation of a bread baking technique using Claude AI."""
    if not request.technique.strip():
        raise HTTPException(status_code=400, detail="Technique cannot be empty")

    # Sanitize input
    sanitized_technique = sanitize_input(
        request.technique,
        max_length=MAX_BREAD_NAME_LENGTH,
        field_name="technique"
    )

    # Check cache first (techniques don't change, so long TTL)
    cache_key = generate_cache_key(sanitized_technique, "technique")
    cached = get_cached_response(cache_key)

    if cached:
        technique_data = cached["response_data"]
        return TechniqueResponse(**technique_data, cached=True)

    try:
        message = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=1000,
            messages=[
                {"role": "user", "content": TECHNIQUE_PROMPT.format(technique=sanitized_technique)}
            ]
        )

        response_text = message.content[0].text.strip()

        # Parse JSON response
        try:
            technique_data = json.loads(response_text)
        except json.JSONDecodeError:
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                technique_data = json.loads(json_match.group())
            else:
                raise HTTPException(status_code=500, detail="Failed to parse technique explanation")

        # Cache the technique (24 hour TTL)
        cache_response(
            cache_key=cache_key,
            cache_type="technique",
            query=sanitized_technique,
            response_data=technique_data,
            prompt_variant="technique_default",
            ttl_seconds=86400
        )

        return TechniqueResponse(**technique_data, cached=False)

    except anthropic.APIConnectionError:
        raise HTTPException(status_code=503, detail="Unable to connect to AI service")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please try again later.")
    except anthropic.APIStatusError as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


# =============================================================================
# TROUBLESHOOTING ENDPOINT
# =============================================================================

TROUBLESHOOT_PROMPT = """Diagnose and solve this bread baking problem: {problem}

Provide a structured troubleshooting guide covering:
1. Likely causes (3-4 most common reasons)
2. Solutions (specific fixes for each cause)
3. Prevention tips (how to avoid this in the future)

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
    "problem": "{problem}",
    "likely_causes": [
        "First likely cause",
        "Second likely cause",
        "Third likely cause"
    ],
    "solutions": [
        "Solution for first cause",
        "Solution for second cause",
        "Solution for third cause"
    ],
    "prevention_tips": [
        "First prevention tip",
        "Second prevention tip",
        "Third prevention tip"
    ]
}}

Be specific and practical. Focus on actionable solutions."""


@app.post("/troubleshoot", response_model=TroubleshootResponse)
async def troubleshoot_problem(request: TroubleshootRequest):
    """Diagnose bread baking problems and provide solutions using Claude AI."""
    if not request.problem.strip():
        raise HTTPException(status_code=400, detail="Problem description cannot be empty")

    # Sanitize input to prevent prompt injection
    sanitized_problem = sanitize_input(
        request.problem,
        max_length=MAX_QUERY_LENGTH,
        field_name="problem"
    )

    # Check cache (common problems can be cached)
    cache_key = generate_cache_key(sanitized_problem, "troubleshoot")
    cached = get_cached_response(cache_key)

    if cached:
        troubleshoot_data = cached["response_data"]
        return TroubleshootResponse(**troubleshoot_data)

    try:
        message = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=1200,
            messages=[
                {"role": "user", "content": TROUBLESHOOT_PROMPT.format(problem=sanitized_problem)}
            ]
        )

        response_text = message.content[0].text.strip()

        # Parse JSON response
        try:
            troubleshoot_data = json.loads(response_text)
        except json.JSONDecodeError:
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if json_match:
                troubleshoot_data = json.loads(json_match.group())
            else:
                raise HTTPException(status_code=500, detail="Failed to parse troubleshooting response")

        # Cache the troubleshooting response (1 hour TTL)
        cache_response(
            cache_key=cache_key,
            cache_type="troubleshoot",
            query=sanitized_problem,
            response_data=troubleshoot_data,
            prompt_variant="troubleshoot_default",
            ttl_seconds=CACHE_TTL_ASK
        )

        return TroubleshootResponse(**troubleshoot_data)

    except anthropic.APIConnectionError:
        raise HTTPException(status_code=503, detail="Unable to connect to AI service")
    except anthropic.RateLimitError:
        raise HTTPException(status_code=429, detail="Rate limit exceeded. Please try again later.")
    except anthropic.APIStatusError as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
