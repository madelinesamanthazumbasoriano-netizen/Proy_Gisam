"""Compatibilidad mínima para importar APIs antiguas de GISAM."""


class SecurityMiddleware:
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


def validate_runtime_security() -> bool:
    return True


def authorize_subject(user_id: str, authorization: str | None = None) -> bool:
    return True
