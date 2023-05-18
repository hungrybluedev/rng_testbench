module main

import arrays
import net.http
import os
import strings
// import szip
import time
import encoding.base64
import x.json2

struct ResultStruct {
	name string
mut:
	ent_norm      f64
	dhr_score     int
	burn_duration f64
	burn_speed    f64
	classic_score int
	classic_count int
	classic_frac  f64
}

[params]
struct OutputOptions {
	report_ent     bool = true
	report_dhr     bool = true
	report_burn    bool = true
	report_classic bool = true
}

fn generate_report(contexts map[string]&EvaluationContext, timestamp string, output OutputOptions) {
	mut results := map[string]ResultStruct{}

	for name in enabled_generators {
		results[name] = ResultStruct{
			name: name
			ent_norm: 0
			dhr_score: 0
			burn_duration: 0
			burn_speed: 0
			classic_score: 0
		}
	}

	for _, context in contexts {
		results[context.name].ent_norm += context.ent_norm
		// results[context.name].dhr_pass += context.dhr_pass
		// results[context.name].dhr_weak += context.dhr_weak
		// results[context.name].dhr_fail += context.dhr_fail
		results[context.name].dhr_score += context.dhr_score
		// results[context.name].ent_duration += context.ent_duration.seconds()
		// results[context.name].dhr_duration += context.dhr_duration.seconds()
		results[context.name].burn_duration += context.burn_duration.seconds()
		results[context.name].classic_score += context.classic_score
		results[context.name].classic_count += context.classic_count
	}

	iterations_f := f64(parameters.iterations)
	burn_iterations_f := f64(parameters.burn_iterations)

	for name in enabled_generators {
		results[name].ent_norm /= iterations_f
		results[name].burn_duration /= iterations_f
		results[name].burn_speed = (burn_iterations_f / (1024.0 * 1024.0)) / results[name].burn_duration
		results[name].classic_frac = f64(results[name].classic_score) / f64(results[name].classic_count)
	}

	mut buffer := strings.new_builder(contexts.len * 100)

	buffer.write_string('Name')

	if output.report_ent {
		buffer.write_string(',Entropy Norm')
	}

	if output.report_dhr {
		buffer.write_string(',DH Score')
	}

	if output.report_burn {
		buffer.write_string(',Burn Speed (MB/s)')
	}

	if output.report_classic {
		buffer.write_string(',Classic')
	}

	buffer.writeln('')

	for name, result in results {
		buffer.write_string('${name}')

		if output.report_ent {
			buffer.write_string(',${result.ent_norm:.4f}')
		}

		if output.report_dhr {
			buffer.write_string(',${result.dhr_score}')
		}

		if output.report_burn {
			buffer.write_string(',${result.burn_speed:.4f}')
		}

		if output.report_classic {
			buffer.write_string(',${result.classic_frac:.4f}')
		}

		buffer.writeln('')
	}

	os.write_file('results/summary ${timestamp}.csv', buffer.str()) or {
		panic('Failed to write summary file')
	}

	println('Results written...')

	time.sleep(2000)

	// szip.zip_files(dump(os.walk_ext('logs', 'log')), 'results/logs ${timestamp}.zip') or {
	// 	panic('Failed to zip logs')
	// }
	cmd := 'zip -r "results/logs ${timestamp}.zip" -r logs'
	println('Zipping logs with: ${cmd}')
	os.execute_or_panic(cmd)
	println('... zipping done')
}

fn pretty_table_from_csv(path string) !string {
	lines := os.read_lines(path)!

	if lines.len < 1 {
		return error('CSV should have at least one line')
	}

	header := lines[0].split(',')
	column_count := header.len

	mut column_widths := []int{len: column_count, init: header[index].len}

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

	single_line_length := arrays.sum(column_widths)! + (column_count + 1) * 3 - 4

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

fn send_detail_report_mail(timestamp string) ! {
	pretty_table := pretty_table_from_csv('results/summary ${timestamp}.csv')!
	subject := 'Experiment Result Summary (${time.now().format()})'
	body := 'Summary of experiment results on ${parameters.system_name}

Date and Time: ${timestamp}

${pretty_table}
'
	send_mail(subject, body)!
}

fn send_test_mail() ! {
	result := os.execute_or_panic('v doctor')
	body := 'Sample email containing metadata on V installation and hardware information.
System: ${parameters.system_name}
Results of "v doctor":
${result.output}
'
	send_mail('Test email from RNG Testbench', body)!
}

pub struct Person {
	email string [json: 'Email']
	name  string [json: 'Name']
}

pub struct Message {
	from      Person   [json: 'From']
	to        []Person [json: 'To']
	subject   string   [json: 'Subject']
	text_part string   [json: 'TextPart']
}

pub struct MailJet {
	sandbox_mode bool      [json: 'SandboxMode']
	messages     []Message [json: 'Messages']
}

fn send_mail(subject string, body string) ! {
	host := 'https://api.mailjet.com/v3.1/send'
	auth_string := base64.encode_str(parameters.api_key + ':' + parameters.secret_key)
	user_agent := 'V RNG TestBench on ${parameters.system_name}'
	raw_recipients := parameters.recipients.split(';')
	clean_body := body.replace('\n', '\\n')

	mut recipients := []Person{}
	for index, r in raw_recipients {
		rname := r.all_before(' <').trim_space()
		email := r.all_after_first(' <').trim('>')
		recipients << Person{
			email: email
			name: rname
		}
	}

	mailjet_info := MailJet{
		sandbox_mode: true
		messages: [
			Message{
				from: Person{
					email: parameters.from_email
					name: 'V RNG Test Bench on ' + parameters.system_name
				}
				to: recipients
				subject: subject
				text_part: clean_body
			},
		]
	}
	data_json := json2.encode[MailJet](mailjet_info)

	mut request := http.Request{
		method: .post
		header: http.new_header_from_map({
			http.CommonHeader.authorization: 'Basic ${auth_string}'
			http.CommonHeader.content_type:  'application/json'
		})
		url: host
		user_agent: user_agent
		data: data_json
	}

	dump(request)
	response := request.do() or { panic(err) }
	dump(response)
}
