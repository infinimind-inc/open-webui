export type VideoParamConfig = {
  id: string;
  label: string;
  description?: string;
  valueLabel?: string;
  modelMatch: (modelId: string) => boolean;
  paramPath: string[];
  min: number;
  max: number;
  step: number;
  defaultValue: number;
  allowedValues?: number[];
  showSlider?: boolean;
};

export const VIDEO_PARAM_CONFIGS: VideoParamConfig[] = [
  {
    id: 'qwen_3_5_longest_edge',
    label: 'Qwen 3.5 (mm_processor_kwargs)',
    valueLabel: 'Longest edge',
    description: 'Set the longest edge used when resizing video frames.',
    modelMatch: (modelId: string) =>
      modelId.toLowerCase().indexOf('qwen') >= 0 && modelId.indexOf('3.5') >= 0,
    paramPath: ['mm_processor_kwargs', 'size', 'longest_edge'],
    min: 1024,
    max: 10240000,
    step: 256,
    defaultValue: 10240000
  },
  {
    id: 'qwen_3_5_fps',
    label: 'Qwen 3.5 (video fps)',
    valueLabel: 'FPS',
    description:
      'Set frames per second to attach alongside each video_url content item (not in mm_processor_kwargs).',
    modelMatch: (modelId: string) =>
      modelId.toLowerCase().indexOf('qwen') >= 0 && modelId.indexOf('3.5') >= 0,
    paramPath: ['video', 'fps'],
    min: 1,
    max: 60,
    step: 1,
    defaultValue: 1,
    showSlider: false
  },
  {
    id: 'gemma_4_max_soft_tokens',
    label: 'Gemma 4 (mm_processor_kwargs)',
    valueLabel: 'Max soft tokens',
    description:
      'Set the max_soft_tokens used when processing video input for Gemma 4 models.',
    modelMatch: (modelId: string) => {
      const lower = modelId.toLowerCase();
      return lower.indexOf('gemma') >= 0 && (lower.indexOf('4') >= 0 || lower.indexOf('-4') >= 0);
    },
    paramPath: ['mm_processor_kwargs', 'max_soft_tokens'],
    min: 70,
    max: 1120,
    step: 1,
    defaultValue: 280,
    allowedValues: [70, 140, 280, 560, 1120]
  },
  {
    id: 'gemma_4_fps',
    label: 'Gemma 4 (video fps)',
    valueLabel: 'FPS',
    description:
      'Set frames per second to attach alongside each video_url content item (not in mm_processor_kwargs).',
    modelMatch: (modelId: string) => {
      const lower = modelId.toLowerCase();
      return lower.indexOf('gemma') >= 0 && (lower.indexOf('4') >= 0 || lower.indexOf('-4') >= 0);
    },
    paramPath: ['video', 'fps'],
    min: 1,
    max: 60,
    step: 1,
    defaultValue: 1,
    showSlider: false
  },
  {
    id: 'deepframe_longest_edge',
    label: 'DeepFrame (mm_processor_kwargs)',
    valueLabel: 'Longest edge',
    description: 'Set the longest edge used when resizing video frames.',
    modelMatch: (modelId: string) => modelId.toLowerCase().includes('infinimind/deepframe'),
    paramPath: ['mm_processor_kwargs', 'size', 'longest_edge'],
    min: 1024,
    max: 10240000,
    step: 256,
    defaultValue: 10240000
  },
  {
    id: 'deepframe_fps',
    label: 'DeepFrame (video fps)',
    valueLabel: 'FPS',
    description:
      'Set frames per second to attach alongside each video_url content item (not in mm_processor_kwargs).',
    modelMatch: (modelId: string) => modelId.toLowerCase().includes('infinimind/deepframe'),
    paramPath: ['video', 'fps'],
    min: 1,
    max: 60,
    step: 1,
    defaultValue: 1,
    showSlider: false
  }
];
