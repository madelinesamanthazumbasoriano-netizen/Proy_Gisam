class UserMemory:
    def __init__(self, repository=None): self.repository = repository
    def retrieve(self, user_id: str, text: str, limit: int = 5):
        if self.repository and hasattr(self.repository, "retrieve"):
            return self.repository.retrieve(user_id, text, limit)
        return []
    def remember(self, user_id: str, text: str, approved: bool = False):
        if not approved: return False
        if self.repository and hasattr(self.repository, "save"): self.repository.save(user_id, text)
        return True
