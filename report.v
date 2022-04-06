module main

import arrays
import net.http
import net.urllib
import os
import strings
import szip
import time

fn generate_report(contexts map[string]&EvaluationContext, timestamp string) {
	mut buffer := strings.new_builder(contexts.len * 100)

	buffer.writeln('Name,Iteration,Entropy Norm,DH Pass,DH Weak,DH Fail,DH Score,Entropy Time (s),DH Time (s)')

	for _, context in contexts {
		buffer.writeln('$context.name,$context.iteration,${context.ent_norm:.4f},$context.dhr_pass,$context.dhr_weak,$context.dhr_fail,$context.dhr_score,${context.ent_duration.seconds():.4f},${context.dhr_duration.seconds():.4f}')
	}

	os.write_file('results/summary ${timestamp}.csv', buffer.str()) or {
		panic('Failed to write summary file')
	}

	szip.zip_files(os.walk_ext('logs', 'log'), 'results/logs ${timestamp}.zip') or {
		panic('Failed to zip logs')
	}
}

fn pretty_table_from_csv(path string) ?string {
	lines := os.read_lines(path) ?

	if lines.len < 1 {
		return error('CSV should have at least one line')
	}

	header := lines[0].split(',')
	max_line_length := arrays.max(lines.map(it.len)) or { panic('Could not find max line length') }
	column_count := header.len

	mut column_widths := []int{len: column_count, init: header[it].len}
	mut buffer := strings.new_builder(lines.len * (max_line_length + column_count * 3))

	for line in lines[1..] {
		values := line.split(',').map(it.trim_space())
		if values.len != column_count {
			return error('CSV line has wrong number of columns')
		}
		for col, value in values {
			if column_widths[col] < value.len {
				column_widths[col] = value.len
			}
		}
	}

	horizontal_line := '+' + strings.repeat(`-`, max_line_length + column_count * 2 + 4) + '+'

	buffer.writeln(horizontal_line)

	buffer.write_string('| ')
	for col, head in header {
		if col != 0 {
			buffer.write_string(' | ')
		}
		buffer.write_string(head)
		buffer.write_string(strings.repeat(` `, column_widths[col] - head.len))
	}
	buffer.writeln(' |')

	buffer.writeln(horizontal_line)

	for line in lines[1..] {
		buffer.write_string('| ')
		for col, value in line.split(',') {
			if col != 0 {
				buffer.write_string(' | ')
			}
			buffer.write_string(value)
			buffer.write_string(strings.repeat(` `, column_widths[col] - value.len))
		}
		buffer.writeln(' |')
	}

	buffer.writeln(horizontal_line)

	return buffer.str()
}

fn send_mail(timestamp string) ? {
	html_table := pretty_table_from_csv('results/summary ${timestamp}.csv') ?

	host := 'https://api.elasticemail.com/v2/email/send'
	subject := 'Experiment Result Summary ($time.now().format())'
	body := '

Summary of experiment results.

Date: $timestamp

General Summary:

$html_table
'

	url := '$host?apiKey=$api_key&to=$recipients&from=$from_email&fromName=RNG Testbench&subject=${urllib.query_escape(subject)}&bodyText=${urllib.query_escape(body)}'

	response := http.post_json(url, '{Content-Length: $url.len}') ?

	println(response.text)

	println('Mail sent!')

	// szip.zip_files(['tocompress/sample.text', 'tocompress/next.text'], 'sample.zip') ?
	// szip.extract_zip_to_dir('sample.zip', 'decompressed') ?
	// contents := os.read_file('sample.zip') ?

	// os.write_file('sample2.zip', contents) ?
}
