module main

import os
import strings

fn generate_report(contexts map[string]&EvaluationContext) {
	mut buffer := strings.new_builder(contexts.len * 100)

	buffer.writeln('Name,Iteration,"Entropy Norm","DH Pass","DH Weak","DH Fail","DH Score"')

	for name, context in contexts {
		buffer.writeln('$name,$context.iteration,${context.ent_norm:.4f},$context.dhr_pass,$context.dhr_weak,$context.dhr_fail,$context.dhr_score')
	}
	os.write_file("results/summary.csv", buffer.str()) or {
		panic('Failed to write summary file')
	}
}
