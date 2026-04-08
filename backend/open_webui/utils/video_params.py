from typing import Callable, Dict

VIDEO_PARAM_ALLOWLIST: Dict[
    str, Dict[str, Callable[[str], bool] | list[str]]
] = {
    "qwen_3_5": {
        "match": lambda model_id: "qwen" in model_id.lower()
        and "3.5" in model_id,
        "allowed_params": ["mm_processor_kwargs"],
    },
    "gemma_4": {
        "match": lambda model_id: "gemma" in model_id.lower()
        and ("-4" in model_id.lower() or " 4" in model_id.lower() or "4" in model_id),
        "allowed_params": ["mm_processor_kwargs"],
    },
    "deepframe": {
        "match": lambda model_id: "infinimind/deepframe" in model_id.lower(),
        "allowed_params": ["mm_processor_kwargs"],
    }
}


def filter_video_params(model_id: str, params: dict) -> dict:
    for entry in VIDEO_PARAM_ALLOWLIST.values():
        match = entry.get("match")
        if match and match(model_id):
            return params

    filtered = params.copy()
    for entry in VIDEO_PARAM_ALLOWLIST.values():
        for param in entry.get("allowed_params", []):
            filtered.pop(param, None)

    return filtered
