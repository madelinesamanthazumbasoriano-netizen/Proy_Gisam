from __future__ import annotations
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from .user_state import (
    init_state_db, profile, update_profile, missions,
    complete_mission, friends, add_friend
)

router = APIRouter(prefix="/users", tags=["users"])


class ProfileUpdate(BaseModel):
    display_name: str = Field(min_length=1, max_length=80)
    bio: str = Field(default="", max_length=500)
    avatar: str = Field(default="default", max_length=120)


class FriendLink(BaseModel):
    friend_id: str = Field(min_length=1, max_length=128)


@router.get("/{user_id}/profile")
def get_profile(user_id: str):
    return profile(user_id)


@router.put("/{user_id}/profile")
def put_profile(user_id: str, req: ProfileUpdate):
    return update_profile(user_id, req.display_name, req.bio, req.avatar)


@router.get("/{user_id}/missions")
def get_missions(user_id: str):
    return {"missions": missions(user_id)}


@router.post("/{user_id}/missions/{mission_id}/complete")
def finish_mission(user_id: str, mission_id: int):
    result = complete_mission(user_id, mission_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Misión no encontrada")
    return result


@router.get("/{user_id}/friends")
def get_friends(user_id: str):
    return {"friends": friends(user_id)}


@router.post("/{user_id}/friends/link")
def link_friend(user_id: str, req: FriendLink):
    if not add_friend(user_id, req.friend_id):
        raise HTTPException(status_code=400, detail="No se puede agregar este usuario")
    return {"ok": True}
