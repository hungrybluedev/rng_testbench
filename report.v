module main

import arrays
import net.http
import net.urllib
import os
import strings
import szip
import time

struct ResultStruct {
	name string
mut:
	ent_norm      f64
	dhr_pass      int
	dhr_weak      int
	dhr_fail      int
	dhr_score     int
	ent_duration  f64
	dhr_duration  f64
	burn_duration f64
	burn_speed    f64
}

fn generate_report(contexts map[string]&EvaluationContext, timestamp string) {
	mut buffer := strings.new_builder(contexts.len * 100)

	buffer.writeln('Name,Entropy Norm,DH Pass,DH Weak,DH Fail,DH Score,Entropy Time (s),DH Time (s),Burn Time (s),Burn Speed (MB/s)')

	mut results := map[string]ResultStruct{}

	for name in enabled_generators {
		results[name] = ResultStruct{
			name: name
			ent_norm: 0
			dhr_pass: 0
			dhr_weak: 0
			dhr_fail: 0
			dhr_score: 0
			ent_duration: 0
			dhr_duration: 0
			burn_duration: 0
			burn_speed: 0
		}
	}

	for _, context in contexts {
		results[context.name].ent_norm += context.ent_norm
		results[context.name].dhr_pass += context.dhr_pass
		results[context.name].dhr_weak += context.dhr_weak
		results[context.name].dhr_fail += context.dhr_fail
		results[context.name].dhr_score += context.dhr_score
		results[context.name].ent_duration += context.ent_duration.seconds()
		results[context.name].dhr_duration += context.dhr_duration.seconds()
		results[context.name].burn_duration += context.burn_duration.seconds()
	}

	iterations_f := f64(iterations)
	burn_iterations_f := f64(burn_iterations)

	for name in enabled_generators {
		results[name].ent_norm /= iterations_f
		results[name].ent_duration /= iterations_f
		results[name].dhr_duration /= iterations_f
		results[name].burn_duration /= iterations_f
		results[name].burn_speed = (burn_iterations_f / (1024.0 * 1024.0)) / results[name].burn_duration
	}

	for name, result in results {
		buffer.writeln('$name,${result.ent_norm:.4f},$result.dhr_pass,$result.dhr_weak,$result.dhr_fail,$result.dhr_score,${result.ent_duration:.4f},${result.dhr_duration:.4f},${result.burn_duration:.4f},${result.burn_speed:.4f}')
	}

	os.write_file('results/summary ${timestamp}.csv', buffer.str()) or {
		panic('Failed to write summary file')
	}

	println('Results written...')
	szip.zip_files(dump(os.walk_ext('logs', 'log')), 'results/logs ${timestamp}.zip') or {
		panic('Failed to zip logs')
	}
}

fn pretty_table_from_csv(path string) ?string {
	lines := os.read_lines(path) ?

	if lines.len < 1 {
		return error('CSV should have at least one line')
	}

	header := lines[0].split(',')
	column_count := header.len

	mut column_widths := []int{len: column_count, init: header[it].len}

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

	single_line_length := arrays.sum(column_widths) ? + (column_count + 1) * 3 - 4

	horizontal_line := '+' + strings.repeat(`-`, single_line_length) + '+'
	mut buffer := strings.new_builder(lines.len * single_line_length)

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

fn send_detail_report_mail(timestamp string) ? {
	pretty_table := pretty_table_from_csv('results/summary ${timestamp}.csv') ?
	subject := 'Experiment Result Summary ($time.now().format())'
	body := 'Summary of experiment results on $system_name

Date and Time: $timestamp

$pretty_table
'
	send_mail(subject, body) ?
}

fn send_test_mail() ? {
	result := os.execute_or_panic('v doctor')
	body := 'Sample email containing metadata on V installation and hardware information.
System: $system_name
Results of "v doctor":
$result.output
'
	send_mail('Test email from RNG Testbench', body) ?
}

fn send_mail(subject string, body string) ? {
	host := 'https://api.elasticemail.com/v2/email/send'

	url := '$host?apiKey=$api_key&to=$recipients&from=$from_email&fromName=RNG Testbench&subject=${urllib.query_escape(subject)}&bodyText=${urllib.query_escape(body)}'

	response := http.post_json(url, '{Content-Length: $url.len}') ?

	println(response.text)
	println('Mail sent!')
}
