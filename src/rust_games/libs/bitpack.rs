pub fn bitpack<F>(get_val: F, num_values: usize, max_value: u8) -> Vec<u8> 
where  F: Fn(usize) -> u8, {
	let max_value = max_value + 1;
	let bits_per_value = (8 - max_value.leading_zeros()) as usize;
	assert_eq!(bits_per_value, 2);
    let mut packed = Vec::new();
    let mut current_byte = 0u8;
    let mut bits_used = 0;

    for i in 0..num_values {
        let value = get_val(i);
        assert!(
            value <= max_value,
            "Value at index {} exceeds max_value: {} > {}",
            i, value, max_value
        );

        current_byte |= (value << bits_used) as u8;
        bits_used += bits_per_value;

        if bits_used >= 8 {
            packed.push(current_byte);
            bits_used -= 8;
            current_byte = if bits_used > 0 {
                (value >> (bits_per_value - bits_used)) as u8
            } else {
                0
            };
        }
    }

    // Push the last byte if there are remaining bits
    if bits_used > 0 {
        packed.push(current_byte);
    }

	println!("packed {} vals into {} bytes", num_values, packed.len());
    packed
}

pub fn bitunpack<F>(packed: &[u8], num_values: usize, max_value: u8, mut store_value: F)
where
    F: FnMut(u8, usize),
{
	let max_value = max_value + 1;
    let bits_per_value = (8 - max_value.leading_zeros()) as usize;
	assert_eq!(bits_per_value, 2);
    let mut byte_index = 0;
    let mut bits_used = 0;
    let mut current_byte = packed[byte_index];

    for i in 0..num_values {
        let mask = (1 << bits_per_value) - 1;
        let value = (current_byte >> bits_used) & mask;
		assert!(value <= max_value, "value is {}", value);

        store_value(value as u8, i);

        bits_used += bits_per_value;

        if bits_used >= 8 {
            bits_used -= 8;
            byte_index += 1;
            if byte_index < packed.len() {
                current_byte = packed[byte_index];
            }
        }
    }
}
