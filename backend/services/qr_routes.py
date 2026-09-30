from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from .qr_invites import create_invite, consume_invite
from .user_state import add_friend

router = APIRouter(prefix="/friends", tags=["friends"])


class InviteRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)


class AcceptRequest(BaseModel):
    user_id: str = Field(min_length=1, max_length=128)
    token: str = Field(min_length=10, max_length=2048)


@router.post("/invite")
def invite(req: InviteRequest):
    return {"token": create_invite(req.user_id)}


@router.post("/invite/accept")
def accept(req: AcceptRequest):
    decoded = consume_invite(req.token)
    if not decoded:
        raise HTTPException(status_code=400, detail="Invitación inválida o expirada")
    owner, _ = decoded
    if owner == req.user_id:
        raise HTTPException(status_code=400, detail="No puedes agregarte a ti mismo")
    add_friend(req.user_id, owner)
    return {"ok": True, "friend_id": owner}
