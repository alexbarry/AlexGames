import argparse
import collections
import subprocess

AppleDimInfo = collections.namedtuple('AppleDimInfo', field_names = [
	'device_width',
	'device_height',
	'pixel_ratio',
	'orientation',
	'output_width',
	'output_height'
])


apple_dims = [
	AppleDimInfo( 320,  568,  2, 'landscape',     1136,  640),
	AppleDimInfo( 375,  812,  3, 'landscape',     2436, 1125),
	AppleDimInfo( 414,  896,  2, 'landscape',     1792,  828),
	AppleDimInfo( 414,  896,  2, 'portrait',       828, 1792),
	AppleDimInfo( 375,  667,  2, 'landscape',     1334,  750),
	AppleDimInfo( 414,  896,  3, 'portrait',      1242, 2688),
	AppleDimInfo( 414,  736,  3, 'landscape',     2208, 1242),
	AppleDimInfo( 375,  812,  3, 'portrait',      1125, 2436),
	AppleDimInfo( 414,  736,  3, 'portrait',      1242, 2208),
	AppleDimInfo(1024, 1366,  2, 'landscape',     2732, 2048),
	AppleDimInfo( 414,  896,  3, 'landscape',     2688, 1242),
	AppleDimInfo( 834, 1112,  2, 'landscape',     2224, 1668),
	AppleDimInfo( 375,  667,  2, 'portrait',       750, 1334),
	AppleDimInfo(1024, 1366,  2, 'portrait',      2048, 2732),
	AppleDimInfo( 834, 1194,  2, 'landscape',     2388, 1668),
	AppleDimInfo( 834, 1112,  2, 'portrait',      1668, 2224),
	AppleDimInfo( 320,  568,  2, 'portrait',       640, 1136),
	AppleDimInfo( 834, 1194,  2, 'portrait',      1668, 2388),
	AppleDimInfo( 768, 1024,  2, 'landscape',     2048, 1536),
	AppleDimInfo( 768, 1024,  2, 'portrait',      1536, 2048),
]

def parse_args():
	parser = argparse.ArgumentParser(
		prog='generate_apple_icons',
		description='Takes an image as input (usually the icon of your app), and generates images '
		            'of every size needed by Apple devices for web app splash screens.'
	)
	parser.add_argument('icon_image', help='Path to icon to place in the center of the output image.')
	parser.add_argument('output_base_name', help='Output images will be this path/string with an underscore and the dimensions added to them e.g. "output_base_name_1920x1080"')

	parser.add_argument('--background_color', default='#000')
	parser.add_argument('--output_extension', default='png')
	parser.add_argument('--icon_width', default='400', type=int)
	parser.add_argument('--href_prefix', default='', help='String to place before the href link when generating HTML. (i.e. the path) Must contain a trailing separator, i.e. this should be "img/", not "img"')
	return parser.parse_args()

def gen_image(icon_image, output_name, output_dimensions, args):
	subprocess.check_output(['convert',
		icon_image,
		'-resize', 'x%d' % args['icon_width'],
		'-gravity', 'center',
		'-background', args['background_color'],
		'-extent', output_dimensions,
		output_name,
	])

def gen_html_tag(device_width, device_height, pixel_ratio, orientation, href):
	return """
	<link
		rel="apple-touch-startup-image"
		media="screen and (device-width: {device_width}px) and (device-height: {device_height}px) and (-webkit-device-pixel-ratio: {pixel_ratio}) and (orientation: {orientation})"
		href="{href}"
    />
""".format(device_width=device_width,
	       device_height=device_height,
	       pixel_ratio=pixel_ratio,
	       orientation=orientation,
	       href=href)


if __name__ == '__main__':
	args = parse_args()

	htmls = []
	for dim in apple_dims:
		if dim.orientation == 'portrait':
			assert dim.device_width  * dim.pixel_ratio == dim.output_width
			assert dim.device_height * dim.pixel_ratio == dim.output_height
		elif dim.orientation == 'landscape':
			assert dim.device_width  * dim.pixel_ratio == dim.output_height
			assert dim.device_height * dim.pixel_ratio == dim.output_width
		else:
			raise Exception()
		output_name = args.output_base_name + '_%dx%d' % (dim.output_width, dim.output_height) + '.%s' % args.output_extension
		output_dimensions = '%dx%d' % (dim.output_width, dim.output_height)
		gen_image(args.icon_image, output_name, output_dimensions, { 'background_color': args.background_color, 'icon_width': args.icon_width})
		href = args.href_prefix + output_name
		htmls.append(gen_html_tag(dim.device_width, dim.device_height, dim.pixel_ratio, dim.orientation, href))

	for html in htmls:
		print(html)
