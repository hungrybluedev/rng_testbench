module main

import os

fn generate_data_file(mut context EvaluationContext) ! {
	file_path := 'data/${context.name}_${context.iteration:02}.dat'
	context.data_file = file_path

	mut data_file := os.open_file(file_path, 'w') or {
		context.logger.fatal('Could not open ${file_path} for writing')
		return
	}
	context.logger.info('Writing data to ${file_path}')

	mut bytes_remaining := parameters.data_file_bytes_count

	for bytes_remaining > 0 {
		mut byte_data := context.rng.bytes(if bytes_remaining > context.buffer_size {
			context.buffer_size
		} else {
			bytes_remaining
		}) or { context.logger.fatal('Failed to generate data') }

		bytes_remaining -= data_file.write(byte_data) or {
			context.logger.fatal('Failed to write data')
		}
	}

	context.logger.info('Wrote ${parameters.data_file_bytes_count} bytes to ${file_path}')

	data_file.close()
}
