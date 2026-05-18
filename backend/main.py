import os
import random
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Dravidian Learn ITS Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase Client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

class AuthSyncRequest(BaseModel):
    user_id: str
    email: str
    display_name: str
    role: str = "child"

class SubmissionRequest(BaseModel):
    user_id: str
    session_id: str
    exercise_id: str
    answer: str
    is_correct: bool
    response_time_ms: int

@app.post("/auth/sync")
async def auth_sync(req: AuthSyncRequest):
    """Upserts user profile on login."""
    try:
        data, count = supabase.table("profiles").upsert({
            "id": req.user_id,
            "display_name": req.display_name,
            "role": req.role
        }).execute()
        return {"status": "ok", "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/exercises/next")
async def get_next_exercise(user_id: str, language: str):
    """Rule-based ITS logic to pick the next exercise."""
    
    # 1. Get all skills for the language in order
    all_skills = supabase.table("skills").select("*").eq("language", language).execute().data
    if not all_skills:
        raise HTTPException(status_code=404, detail="No skills found for language")
    
    # Sort skills by prerequisite chain (naive approach for MVP)
    # In a full app, we'd use a graph traversal or a depth field.
    # Here we assume order based on the list if pre-reqs are linear.
    skill_map = {s['id']: s for s in all_skills}
    ordered_skills = []
    
    # Simple linear chain resolver
    curr = next((s for s in all_skills if not s['prerequisite_skill_id']), None)
    while curr:
        ordered_skills.append(curr)
        curr_id = curr['id']
        curr = next((s for s in all_skills if s['prerequisite_skill_id'] == curr_id), None)

    # 2. Get user mastery
    mastery_data = supabase.table("skill_mastery").select("*").eq("user_id", user_id).execute().data
    mastery_map = {m['skill_id']: m['mastery_score'] for m in mastery_data}

    # 3. Find first skill with mastery < 0.8
    target_skill = None
    for skill in ordered_skills:
        score = mastery_map.get(skill['id'], 0.0)
        if score < 0.8:
            target_skill = skill
            break
    
    # 4. If all mastered, pick the one with lowest score for review
    if not target_skill and mastery_data:
        target_skill_id = min(mastery_data, key=lambda x: x['mastery_score'])['skill_id']
        target_skill = skill_map[target_skill_id]
    elif not target_skill:
        target_skill = ordered_skills[0] # Fallback to first

    # 5. Get exercises for the target skill
    exercises = supabase.table("exercises").select("*").eq("skill_id", target_skill['id']).execute().data
    if not exercises:
        raise HTTPException(status_code=404, detail="No exercises found for target skill")

    return {
        "skill": target_skill,
        "exercise": random.choice(exercises)
    }

@app.post("/exercises/submit")
async def submit_exercise(req: SubmissionRequest):
    """Logs the event and updates mastery scores."""
    try:
        # 1. Log session event
        supabase.table("session_events").insert({
            "session_id": req.session_id,
            "event_type": "exercise_submission",
            "payload": {
                "exercise_id": req.exercise_id,
                "is_correct": req.is_correct,
                "response_time_ms": req.response_time_ms,
                "answer": req.answer
            }
        }).execute()

        # 2. Update mastery score (Moving Average or similar simple logic)
        # First, find the skill_id for this exercise
        exercise = supabase.table("exercises").select("skill_id").eq("id", req.exercise_id).single().execute().data
        skill_id = exercise['skill_id']

        # Get current mastery
        existing = supabase.table("skill_mastery").select("*").eq("user_id", req.user_id).eq("skill_id", skill_id).execute().data
        
        current_score = 0.0
        if existing:
            current_score = existing[0]['mastery_score']
        
        # Simple adjustment logic: +0.1 for correct, -0.05 for wrong, clamped [0, 1]
        delta = 0.1 if req.is_correct else -0.05
        new_score = max(0.0, min(1.0, current_score + delta))

        supabase.table("skill_mastery").upsert({
            "user_id": req.user_id,
            "skill_id": skill_id,
            "mastery_score": new_score,
            "last_reviewed_at": "now()"
        }).execute()

        return {"status": "ok", "new_score": new_score}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/progress/{user_id}")
async def get_progress(user_id: str):
    """Returns mastery scores per skill."""
    data = supabase.table("skill_mastery").select("skill_id, mastery_score").eq("user_id", user_id).execute().data
    return data

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)