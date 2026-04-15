<script lang="ts">
    import { WEBUI_BASE_URL } from '$lib/constants';
    import { settings } from '$lib/stores';
    import { getContext } from 'svelte';

    import XMark from '$lib/components/icons/XMark.svelte';

    const i18n = getContext('i18n');

    export let src = '';
    export let poster: string | null = null;

    export let controls = true;
    export let autoplay = false;
    export let loop = false;
    export let muted = false;
    export let playsinline = true;
    export let preload: 'auto' | 'metadata' | 'none' = 'metadata';

    export let className = `w-full ${($settings?.highContrastMode ?? false) ? '' : 'outline-hidden focus:outline-hidden'}`;
    export let videoClassName = 'rounded-lg';

    export let dismissible = false;
    export let onDismiss = () => {};

    export let ariaLabel: string | null = null;

    let source = '';
    let posterSource: string | null = null;

    $: source = src.startsWith('/') ? `${WEBUI_BASE_URL}${src}` : src;
    $: posterSource = poster
        ? poster.startsWith('/')
            ? `${WEBUI_BASE_URL}${poster}`
            : poster
        : null;
</script>

<div class="relative group w-fit flex items-center">
    <div class={className}>
        <video
            class={videoClassName}
            src={source}
            controls={controls}
            autoplay={autoplay}
            loop={loop}
            muted={muted}
            playsinline={playsinline}
            preload={preload}
            poster={posterSource ?? undefined}
            aria-label={ariaLabel ?? undefined}
        >
            {$i18n.t('Your browser does not support the video tag.')}
        </video>
    </div>

    {#if dismissible}
        <div class="absolute -top-1 -right-1">
            <button
                aria-label={$i18n.t('Remove video')}
                class="bg-white text-black border border-white rounded-full {($settings?.highContrastMode ?? false) ? '' : 'outline-hidden focus:outline-hidden group-hover:visible invisible transition'}"
                type="button"
                on:click={() => {
                    onDismiss();
                }}
            >
                <XMark className={'size-4'} />
            </button>
        </div>
    {/if}
</div>
