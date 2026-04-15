
This codebase is the implementation of open-webui, a GUI to interact with LLMs via the OpenAI chat completion API.

I am trying to extend this to incorporate video input, and testing with a model running via an OpenAI compatible VLLM server, which supports the extra parameters defined here: https://docs.vllm.ai/en/stable/serving/openai_compatible_server/#extra-parameters_2

I would like to modify the UI to allow for a more comfortable interaction in passing the parameters.  Let's focus on the following parameters:

```
mm_processor_kwargs = {'size': {'longest_edge': 10240000, 'shortest_edge': 4096}}
```

The value of longest_edge effectively sets the size of the input video (rezising if required).  I would like to add a sliding bar so that this value can be chosen more easily, and then fed as a custom parameter. The idea would be to add this to the "Control" menu, alongside its current entries.

Please lets restart from the plan you generated previously, pasted below.

Summary: I confirmed the backend already forwards arbitrary `params` into the final OpenAI-compatible payload via `apply_params_to_form_data`, so `mm_processor_kwargs` will be sent as long as we set it in `params`. To honor your model-specific requirement, I’ll add a backend guard to **only allow video-related params for explicitly whitelisted models**, while also adding a shared config file for slider ranges on the frontend.


Below is the **redesigned plan** addressing your new points (model detection via `models + params.modelId`, show slider only when video attached, slider ranges stored in config file, plus backend handling in `middleware.py`).

---
# ✅ Updated Plan (with Backend Handling)

## A) Frontend: new “Video” collapsible and model-aware slider
### 1) `src/lib/components/chat/Controls/Controls.svelte`
- Add `VideoControls` component inside a new **“Video”** collapsible.
- Collapsible only **renders if any attached file is video** (matches your point #2).

**Logic:**
```svelte
{#if hasVideoFiles}
  <Collapsible title={$i18n.t('Video')} ...>
    <VideoControls {models} bind:params {chatFiles} />
  </Collapsible>
{/if}
```

`hasVideoFiles` computed from `chatFiles` (type == 'video' or content_type startsWith('video/')).

### 2) New config file for slider ranges
**File:** `src/lib/constants/video-params.ts` (or `.json`)

**Purpose:** Centralize model-specific slider ranges + param path.

**Example:**
```ts
export const VIDEO_PARAM_CONFIG = {
  qwen_3_5: {
    modelMatch: (id: string) => id.includes('qwen') && id.includes('3.5'),
    label: 'Qwen 3.5 (mm_processor_kwargs)',
    paramPath: ['mm_processor_kwargs', 'size', 'longest_edge'],
    min: 1024,
    max: 10240000,
    step: 256,
    defaultValue: 10240000
  }
};
```

### 3) New `VideoControls.svelte`
- Reads config from `video-params.ts`.
- Detects active model using `models` and `params.modelId` (as per your point #1).
- If no config match, show **“Video controls not available for this model.”**
- Writes value into nested `params` path (e.g., `mm_processor_kwargs.size.longest_edge`).

---

## B) Backend: enforce model-specific allowance in middleware
You asked specifically about backend changes (e.g. `backend/open_webui/utils/middleware.py`). The key is to **filter video params unless the model explicitly supports them**.

### ✅ Where it happens now
The request from UI ultimately passes through:
```py
form_data = apply_params_to_form_data(form_data, model)
```
This function copies `params` into `form_data`, so any param (like `mm_processor_kwargs`) already gets forwarded to the LLM.

### ✅ Planned change (guard/allowlist)
Add a **model-allowlist filter** before forwarding parameters, so unsupported models never receive `mm_processor_kwargs` (or other video params):

**New helper (backend)**
**File:** `backend/open_webui/utils/video_params.py` (new)
```py
VIDEO_PARAM_ALLOWLIST = {
    "qwen_3_5": {
        "match": lambda model_id: "qwen" in model_id and "3.5" in model_id,
        "allowed_params": ["mm_processor_kwargs"],
    }
}


def filter_video_params(model_id: str, params: dict) -> dict:
    for entry in VIDEO_PARAM_ALLOWLIST.values():
        if entry["match"](model_id):
            return params
    # If model not supported, strip all known video params
    params = params.copy()
    params.pop("mm_processor_kwargs", None)
    return params
```

**Apply inside `apply_params_to_form_data` in `middleware.py`:**
```py
from open_webui.utils.video_params import filter_video_params

params = filter_video_params(model.get("id", ""), params)
```

**Why:**
- Ensures **model-specific behavior** across the entire stack.
- Prevents accidental misuse of `mm_processor_kwargs` for unsupported models.

---

# ✅ Deliverables Summary
1. **Frontend**: new `Video` collapsible, only shown when video is attached.
2. **Frontend**: `VideoControls.svelte` using `params.modelId` + `models` to select per-model slider.
3. **Frontend**: `video-params.ts` config to store ranges & param paths (your point #3).
4. **Backend**: add `video_params.py` allowlist + filter in `middleware.py` to enforce model-specific param acceptance.

---

# Confirmations Needed
- Is it OK to put the backend allowlist in a **new file** (`open_webui/utils/video_params.py`) rather than inside middleware directly?
- Should the allowlist be **mirrored** from frontend config (future expansion), or keep backend minimal with only model ID matching + allowed keys?

