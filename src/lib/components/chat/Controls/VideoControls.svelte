<script lang="ts">
  import { getContext } from 'svelte';
  import Tooltip from '$lib/components/common/Tooltip.svelte';
  import { VIDEO_PARAM_CONFIGS, type VideoParamConfig } from '$lib/constants/video-params';

  const i18n = getContext('i18n');

  export let models = [];
  export let params = {};

  const getActiveModelId = () => {
    if (params?.modelId) {
      console.log('[VideoControls] modelId from params:', params.modelId);
      return params.modelId;
    }

    const primaryModel = models?.at?.(0) ?? models?.[0];
    const derived = primaryModel?.id ?? primaryModel?.value ?? '';
    console.log('[VideoControls] modelId from models:', derived, primaryModel);
    return derived;
  };

  const getValueAtPath = (obj: Record<string, any>, path: string[]) => {
    return path.reduce((acc, key) => (acc && acc[key] !== undefined ? acc[key] : undefined), obj);
  };

  const setValueAtPath = (obj: Record<string, any>, path: string[], value: number) => {
    let cursor = obj;
    path.forEach((key, index) => {
      if (index === path.length - 1) {
        cursor[key] = value;
      } else {
        if (!cursor[key] || typeof cursor[key] !== 'object') {
          cursor[key] = {};
        }
        cursor = cursor[key];
      }
    });
  };

  const normalizeToAllowed = (config: VideoParamConfig, value: number) => {
    const allowed = config.allowedValues;
    if (!allowed || !allowed.length || value === undefined || value === null) return value;
    if (allowed.includes(value)) return value;
    let closest = allowed[0];
    let minDiff = Math.abs(value - closest);
    allowed.forEach((candidate) => {
      const diff = Math.abs(value - candidate);
      if (diff < minDiff) {
        closest = candidate;
        minDiff = diff;
      }
    });
    return closest;
  };

  const getSliderValue = (config: VideoParamConfig, value: number) => {
    if (config.allowedValues?.length) {
      const idx = config.allowedValues.indexOf(value);
      return idx >= 0 ? idx : 0;
    }
    return value;
  };

  $: activeModelId = getActiveModelId();
  $: activeConfigs = VIDEO_PARAM_CONFIGS.filter((config) => config.modelMatch(activeModelId));

  const getCurrentValue = (config: VideoParamConfig) => {
    if (!config || typeof params !== 'object') return null;
    const raw = getValueAtPath(params, config.paramPath) ?? config.defaultValue;
    return normalizeToAllowed(config, raw);
  };

  const updateValue = (config: VideoParamConfig, value: number) => {
    const normalized = normalizeToAllowed(config, value);
    if (!params || typeof params !== 'object') {
      params = {};
    }
    setValueAtPath(params, config.paramPath, normalized);
    params = params;
  };

</script>

<div class="space-y-2 text-xs">
  {#if activeConfigs.length}
    {#each activeConfigs as config (config.id)}
      {#key JSON.stringify(params)}
        {@const value = getCurrentValue(config) ?? config.defaultValue}
        {@const allowedValues = config.allowedValues ?? []}
        {@const isDiscrete = allowedValues.length > 0}
        {@const sliderValue = getSliderValue(config, value)}
        {@const showSlider = config.showSlider ?? true}
        <div class="py-0.5 w-full">
          <Tooltip
            content={config.description ?? $i18n.t('Configure video input settings.')}
            placement="top-start"
            className="inline-tooltip"
          >
            <div class="flex w-full justify-between mb-1">
              <div class="self-center text-xs font-medium">{config.label}</div>
              <span class="text-xs text-gray-500">
                {config.valueLabel ?? config.label}: {value}
              </span>
            </div>
          </Tooltip>
          <div class="flex items-center space-x-2">
            {#if showSlider}
              <input
                type="range"
                min={isDiscrete ? 0 : config.min}
                max={isDiscrete ? Math.max(allowedValues.length - 1, 0) : config.max}
                step={isDiscrete ? 1 : config.step}
                value={sliderValue}
                class="w-full h-2 rounded-lg appearance-none cursor-pointer dark:bg-gray-700"
                title={`${value}`}
                on:input={(event) => {
                  const target = event.target as HTMLInputElement;
                  const raw = Number(target.value);
                  const resolved = isDiscrete ? allowedValues[raw] ?? config.defaultValue : raw;
                  updateValue(config, resolved ?? config.defaultValue);
                }}
              />
            {/if}
            <input
              type="number"
              min={isDiscrete ? allowedValues[0] : config.min}
              max={isDiscrete ? allowedValues[allowedValues.length - 1] : config.max}
              step={isDiscrete ? 1 : config.step}
              value={value}
              class="bg-transparent text-center w-28"
              on:change={(event) => {
                const target = event.target as HTMLInputElement;
                const raw = Number(target.value);
                updateValue(config, raw);
              }}
            />
          </div>
          {#if isDiscrete && showSlider}
            <div class="flex flex-wrap gap-1 mt-1 text-[10px] text-gray-500">
              {#each allowedValues as opt, idx}
                <button
                  type="button"
                  class={`px-1.5 py-0.5 rounded border transition-colors ${
                    opt === value
                      ? 'border-blue-500 text-blue-600 dark:text-blue-300 dark:border-blue-400'
                      : 'border-gray-300 dark:border-gray-600'
                  } ${idx === sliderValue ? 'bg-blue-50 dark:bg-blue-900/30' : ''}`}
                  on:click={() => updateValue(config, opt)}
                >
                  {opt}
                </button>
              {/each}
            </div>
          {/if}
        </div>
      {/key}
    {/each}
  {:else}
    <div class="text-xs text-gray-500">
      {$i18n.t('Video controls are not available for the selected model.')}
    </div>
  {/if}
</div>
