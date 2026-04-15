<script lang="ts">
	import { toast } from 'svelte-sonner';
	import { getContext } from 'svelte';
	import { settings } from '$lib/stores';
	import Modal from '$lib/components/common/Modal.svelte';
	import XMark from '$lib/components/icons/XMark.svelte';

	const i18n = getContext('i18n');

	export let show = false;
	export let onSubmit: (payload: { url: string; name?: string }) => void;

	let url = '';
	let name = '';

	const submitHandler = () => {
		const value = url.trim();
		if (!value) {
			toast.error($i18n.t('Please enter a URL or path.'));
			return;
		}
		onSubmit({ url: value, name: name.trim() || undefined });
		show = false;
		url = '';
		name = '';
	};
</script>

<Modal bind:show size="sm">
	<div class="flex flex-col h-full">
		<div class="flex justify-between items-center dark:text-gray-100 px-5 pt-4 pb-1.5">
			<h1 class="text-lg font-medium self-center font-primary">
				{$i18n.t('Attach Video URL/Path')}
			</h1>
			<button
				class="self-center"
				aria-label={$i18n.t('Close modal')}
				on:click={() => {
					show = false;
				}}
			>
				<XMark className="size-5" />
			</button>
		</div>

		<div class="px-5 pb-4">
			<form
				on:submit={(e) => {
					e.preventDefault();
					submitHandler();
				}}
			>
				<div class="flex justify-between mb-0.5">
					<label
						for="video-pointer-url"
						class={`text-xs ${($settings?.highContrastMode ?? false) ? 'text-gray-800 dark:text-gray-100' : 'text-gray-500'}`}
						>{$i18n.t('URL or path')}</label
					>
				</div>
				<textarea
					id="video-pointer-url"
					class={`w-full flex-1 text-sm bg-transparent ${($settings?.highContrastMode ?? false) ? 'placeholder:text-gray-700 dark:placeholder:text-gray-100' : 'outline-hidden placeholder:text-gray-300 dark:placeholder:text-gray-700'}`}
					type="text"
					bind:value={url}
					rows="3"
					placeholder={'https://example.com/video.mp4 or file:///path/video.mp4'}
					autocomplete="off"
					required
				/>

				<div class="flex justify-between mb-0.5 mt-3">
					<label
						for="video-pointer-name"
						class={`text-xs ${($settings?.highContrastMode ?? false) ? 'text-gray-800 dark:text-gray-100' : 'text-gray-500'}`}
						>{$i18n.t('Display name (optional)')}</label
					>
				</div>
				<input
					id="video-pointer-name"
					class={`w-full text-sm bg-transparent ${($settings?.highContrastMode ?? false) ? 'placeholder:text-gray-700 dark:placeholder:text-gray-100' : 'outline-hidden placeholder:text-gray-300 dark:placeholder:text-gray-700'}`}
					type="text"
					bind:value={name}
					placeholder="My video"
					autocomplete="off"
				/>

				<div class="flex justify-end gap-2 pt-3 bg-gray-50 dark:bg-gray-900/50">
					<button
						class="px-3.5 py-1.5 text-sm font-medium bg-black hover:bg-gray-800 text-white dark:bg-white dark:text-black dark:hover:bg-gray-200 transition rounded-full"
						type="submit"
					>
						{$i18n.t('Add')}
					</button>
				</div>
			</form>
		</div>
	</div>
</Modal>
