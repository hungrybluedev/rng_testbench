module main

import stat_tests as st
import util

fn store_classic_test_results(mut context EvaluationContext) {
	input_types := [
		util.InputType.one_byte,
		util.InputType.upper_u16,
		util.InputType.upper_u32,
		util.InputType.upper_u64,
		util.InputType.fraction,
	]

	for itype in input_types {
		context.logger.info('Testing input type: ${itype}')
		chi_sq_value := st.chi_square_value(mut context.rng, classic_iterations, itype)
		chi_sq_p := st.chi_square_p(chi_sq_value, 255)

		context.logger.info('Chi-square value: ${chi_sq_value}')
		context.logger.info('Chi-square p value: ${chi_sq_p}')
		if chi_sq_p >= 0.05 && chi_sq_p <= 0.95 {
			context.chisq_pass++
			context.logger.info('Chi-square test passed.')
		} else {
			context.logger.warn('Chi-square test failed.')
		}
		context.classic_count++

		kp, km := st.kolsmir(mut context.rng, 1000, itype)

		context.logger.info('Kolmogorov-Smirnov values: ${kp}, ${km}')
		if 0.1548 < kp && kp < 1.2186 && 0.1548 < km && km < 1.2186 {
			context.kolsmir_pass++
			context.logger.info('Kolmogorov-Smirnov test passed.')
		} else {
			context.logger.warn('Kolmogorov-Smirnov test failed.')
		}
		context.classic_count++

		serial_val := st.serial_chi_sq_val(mut context.rng, classic_iterations, itype)
		serial_p := st.serial_chi_sq_p(serial_val)

		context.logger.info('Serial Test value: ${serial_val}')
		context.logger.info('Serial Test p value: ${serial_p}')
		if serial_p >= 0.05 && serial_p <= 0.95 {
			context.serial_pass++
			context.logger.info('Serial Chi-square test passed.')
		} else {
			context.logger.warn('Serial Chi-square test failed.')
		}
		context.classic_count++
	}

	context.classic_score = context.chisq_pass + context.kolsmir_pass + context.serial_pass
}
