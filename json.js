export default `
//Generated automatically, by generate_configs.py
{
  string_templates: [
    {
      key: "data_dir",
      value: "data",
    },
    {
      key: "meshes_dir",
      value: "{data_dir}/shapenet_meshes",
    },
    {
      key: "resnet_cpt",
      value: "{data_dir}/keras_resnet50_imagenet.cpt",
    },
    {
      key: "output_dir",
      value: "output/models",
    },
  ],
  train: {
    data: {
      datasets: [
        {
          dataset_path: "{data_dir}/single.train/dataset.choy_classes.json",
          meshes_dir: "{meshes_dir}",
          high_realism: false,
          shuffle: "PER_EPOCH",
          data_fraction: 1.0,
        },
        {
          dataset_path: "{data_dir}/single.val/dataset.choy_classes.json",
          meshes_dir: "{meshes_dir}",
          high_realism: false,
          shuffle: "PER_EPOCH",
          data_fraction: 1.0,
        },
      ],
      shuffle: "PER_EPOCH",
      data_loader: {
        num_data_workers: 6,
        batch_size: 4,
        prefetch_factor: 2,
      },
      voxelization_config: {
        task_type: "FG_BG",
        resolution: {
          depth: 128,
          height: 128,
          width: 128,
        },
        sub_grid_sampling: false,
        conservative_rasterization: false,
        voxelization_image_resolution_multiplier: 8,
        voxelization_projection_depth_multiplier: 1,
      },
    },
    resnet50_imagenet_checkpoint: "{resnet_cpt}",
    checkpoint_interval: 10000,
    persistent_checkpoint_interval: 500000,
    tensorboard_log_interval: 1000,
    initial_learning_rate: 0.0004,
    adam_epsilon: 0.0001,
    random_grid_offset: false,
    last_upscale_factor: 2,
    latent_channels: 64,
    skip_fraction: 0.75,
    max_steps: 16000000,
  },
  eval: [
    {
      start_step: 40000,
      interval: 40000,
      persistent_checkpoint: false,
      config: {
        name: "short_stable_train_eval",
        data: {
          datasets: [
            {
              dataset_path: "{data_dir}/single.val/dataset.choy_classes.json",
              meshes_dir: "{meshes_dir}",
              high_realism: false,
              shuffle: "ONCE",
              data_fraction: 0.01,
            },
          ],
          shuffle: "ONCE",
          data_loader: {
            num_data_workers: 6,
            batch_size: 4,
            prefetch_factor: 2,
          },
          voxelization_config: {
            task_type: "FG_BG",
            resolution: {
              depth: 128,
              height: 128,
              width: 128,
            },
            sub_grid_sampling: false,
            conservative_rasterization: false,
            voxelization_image_resolution_multiplier: 8,
            voxelization_projection_depth_multiplier: 1,
          },
        },
        num_qualitative_results: 40,
        num_qualitative_results_in_tensor_board: 4,
      },
    },
    {
      start_step: 40000,
      interval: 40000,
      persistent_checkpoint: false,
      config: {
        name: "short_stable_eval",
        data: {
          datasets: [
            {
              dataset_path: "{data_dir}/single.test/dataset.choy_classes.json",
              meshes_dir: "{meshes_dir}",
              high_realism: false,
              shuffle: "ONCE",
              data_fraction: 0.01,
            },
          ],
          shuffle: "ONCE",
          data_loader: {
            num_data_workers: 6,
            batch_size: 4,
            prefetch_factor: 2,
          },
          voxelization_config: {
            task_type: "FG_BG",
            resolution: {
              depth: 128,
              height: 128,
              width: 128,
            },
            sub_grid_sampling: false,
            conservative_rasterization: false,
            voxelization_image_resolution_multiplier: 8,
            voxelization_projection_depth_multiplier: 1,
          },
        },
        num_qualitative_results: 40,
        num_qualitative_results_in_tensor_board: 4,
      },
    },
    {
      start_step: 140000,
      interval: 140000,
      persistent_checkpoint: false,
      config: {
        name: "medium_eval",
        data: {
          datasets: [
            {
              dataset_path: "{data_dir}/single.test/dataset.choy_classes.json",
              meshes_dir: "{meshes_dir}",
              high_realism: false,
              shuffle: "PER_EPOCH",
              data_fraction: 0.1,
            },
          ],
          shuffle: "PER_EPOCH",
          data_loader: {
            num_data_workers: 6,
            batch_size: 4,
            prefetch_factor: 2,
          },
          voxelization_config: {
            task_type: "FG_BG",
            resolution: {
              depth: 128,
              height: 128,
              width: 128,
            },
            sub_grid_sampling: false,
            conservative_rasterization: false,
            voxelization_image_resolution_multiplier: 8,
            voxelization_projection_depth_multiplier: 1,
          },
        },
        num_qualitative_results: 100,
        num_qualitative_results_in_tensor_board: 4,
      },
    },
    {
      start_step: 500000,
      interval: 500000,
      persistent_checkpoint: true,
      config: {
        name: "full_eval",
        data: {
          datasets: [
            {
              dataset_path: "{data_dir}/single.test/dataset.choy_classes.json",
              meshes_dir: "{meshes_dir}",
              high_realism: false,
              shuffle: "ONCE",
              data_fraction: 1.0,
            },
          ],
          shuffle: "ONCE",
          data_loader: {
            num_data_workers: 6,
            batch_size: 4,
            prefetch_factor: 2,
          },
          voxelization_config: {
            task_type: "FG_BG",
            resolution: {
              depth: 128,
              height: 128,
              width: 128,
            },
            sub_grid_sampling: false,
            conservative_rasterization: false,
            voxelization_image_resolution_multiplier: 8,
            voxelization_projection_depth_multiplier: 1,
          },
        },
        num_qualitative_results: 500,
        num_qualitative_results_in_tensor_board: 0,
      },
    },
  ],
  output_path: "{output_dir}/h5",
  $schema: "../schemas/train_config.json",
}
`
