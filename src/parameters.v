module main

import os
import toml

struct ExperimentParameters {
	keep_data             bool
	iterations            u64 = 12
	data_file_bytes_count int = 715128832
	default_block_size    int = 4194304
	burn_iterations       u64 = 5000000000
	classic_iterations    int = 100000

	system_name string = default_system_name()
	from_email  string = 'unset_from_email'
	recipients  string = 'unset_recipients'
	api_key     string = 'unset_api_key'
	secret_key  string = 'unset_secret_key'
}

fn get_experiment_parameters() ExperimentParameters {
	return if os.exists('config.toml') {
		config_file := toml.parse_file('config.toml') or {
			panic('Config file does not have valid TOML.')
		}
		// The experiment parameters first
		experiment := config_file.value_opt('experiment') or {
			panic('Config file is missing experiment section.')
		}
		keep_data := (experiment.value_opt('keep_data') or { 'false' }).string() == 'true'
		iterations := (experiment.value_opt('iterations') or { '12' }).string().u64()
		data_file_bytes_count := (experiment.value_opt('data_file_bytes_count') or { '715128832' }).string().int()
		default_block_size := (experiment.value_opt('default_block_size') or { '4194304' }).string().int()
		burn_iterations := (experiment.value_opt('burn_iterations') or { '5000000000' }).string().u64()
		classic_iterations := (experiment.value_opt('classic_iterations') or { '100000' }).string().int()
		system_name := (experiment.value_opt('system_name') or { default_system_name() }).string()

		// Mail parameters now
		mail := config_file.value_opt('mail') or { panic('Config file is missing mail section.') }
		from_email := (mail.value_opt('from_email') or { 'unset_from_email' }).string()
		recipients := (mail.value_opt('recipients') or { 'unset_recipients' }).string()
		api_key := (mail.value_opt('api_key') or { 'unset_api_key' }).string()
		secret_key := (mail.value_opt('secret_key') or { 'unset_secret_key' }).string()

		ExperimentParameters{
			keep_data: keep_data
			iterations: iterations
			data_file_bytes_count: data_file_bytes_count
			default_block_size: default_block_size
			burn_iterations: burn_iterations
			classic_iterations: classic_iterations
			system_name: system_name
			from_email: from_email
			recipients: recipients
			api_key: api_key
			secret_key: secret_key
		}
	} else {
		ExperimentParameters{}
	}
}
