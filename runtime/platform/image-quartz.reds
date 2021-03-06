Red/System [
	Title:   "Image routine functions using Quartz"
	Author:  "Qingtian Xie"
	File: 	 %image-quartz.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

OS-image: context [

	NSRect!: alias struct! [
		x		[float32!]
		y		[float32!]
		w		[float32!]
		h		[float32!]
	]

	#define kCGBitmapByteOrder32Little 		8192
	#define kCGImageAlphaPremultipliedLast	1
	#define kCGImageAlphaPremultipliedFirst 2
	#define kCGImageAlphaLast				3
	#define kCGImageAlphaFirst				4

	#define kCGImageFormatARGB				8194	;-- kCGImageAlphaPremultipliedFirst or kCGBitmapByteOrder32Little

	#import [
		"/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices" cdecl [
			CGColorSpaceCreateDeviceRGB: "CGColorSpaceCreateDeviceRGB" [
				return:		[integer!]
			]
			CGColorSpaceRelease: "CGColorSpaceRelease" [
				color-space [integer!]
			]
			CGBitmapContextCreate: "CGBitmapContextCreate" [
				buffer		[byte-ptr!]
				width		[integer!]
				height		[integer!]
				bits		[integer!]
				bytes-row	[integer!]
				color-space [integer!]
				bmp-info	[integer!]
				return:		[integer!]
			]
			CGBitmapContextGetWidth: "CGBitmapContextGetWidth" [
				ctx			[integer!]
				return:		[integer!]
			]
			CGBitmapContextGetHeight: "CGBitmapContextGetHeight" [
				ctx			[integer!]
				return:		[integer!]
			]
			CGBitmapContextGetData: "CGBitmapContextGetData" [
				ctx			[integer!]
				return:		[byte-ptr!]
			]
			CGContextRelease: "CGContextRelease" [
				ctx			[integer!]
			]
			CGContextDrawImage: "CGContextDrawImage" [
				ctx			[integer!]
				x			[float32!]
				y			[float32!]
				w			[float32!]
				h			[float32!]
				src			[integer!]
			]
			CGImageSourceCreateWithData: "CGImageSourceCreateWithData" [
				data		[integer!]
				options		[integer!]
				return:		[integer!]
			]
			CGImageSourceCreateImageAtIndex: "CGImageSourceCreateImageAtIndex" [
				src			[integer!]
				index		[integer!]
				options		[integer!]
				return:		[integer!]
			]
			CGImageGetWidth: "CGImageGetWidth" [
				image		[integer!]
				return:		[integer!]
			]
			CGImageGetHeight: "CGImageGetHeight" [
				image		[integer!]
				return:		[integer!]
			]
			CGImageRetain: "CGImageRetain" [
				image		[integer!]
				return:		[integer!]
			]
			CGImageRelease: "CGImageRelease" [
				image		[integer!]
			]
		]
		"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
			CFDataCreate: "CFDataCreate" [
				allocator	[integer!]
				data		[byte-ptr!]
				length		[integer!]
				return:		[integer!]
			]
			CFRelease: "CFRelease" [
				cf			[integer!]
			]
		]
	]

	make-rect: func [
		x		[integer!]
		y		[integer!]
		w		[integer!]
		h		[integer!]
		return: [NSRect!]
		/local
			r	[NSRect!]
	][
		r: declare NSRect!
		r/x: as float32! x
		r/y: as float32! y
		r/w: as float32! w
		r/h: as float32! h
		r
	]

	width?: func [
		handle		[integer!]
		return:		[integer!]
	][
		CGBitmapContextGetWidth handle
	]

	height?: func [
		handle		[integer!]
		return:		[integer!]
	][
		CGBitmapContextGetHeight handle
	]

	lock-bitmap: func [						;-- do nothing on Quartz backend
		handle		[integer!]
		write?		[logic!]
		return:		[integer!]
	][
		handle
	]

	unlock-bitmap: func [					;-- do nothing on Quartz backend
		handle		[integer!]
		data		[integer!]
	][]

	get-data: func [
		handle		[integer!]
		stride		[int-ptr!]
		return:		[int-ptr!]
		/local
			buf		[int-ptr!]
	][
		stride/value: 4 * CGBitmapContextGetWidth handle
		buf: as int-ptr! CGBitmapContextGetData handle
		buf
	]

	get-pixel: func [
		bitmap		[integer!]
		index		[integer!]				;-- zero-based
		return:		[integer!]
		/local
			buf		[int-ptr!]
	][
		buf: as int-ptr! CGBitmapContextGetData bitmap
		buf: buf + index
		buf/value
	]

	set-pixel: func [
		bitmap		[integer!]
		index		[integer!]				;-- zero-based
		color		[integer!]
		return:		[integer!]
		/local
			buf		[int-ptr!]
	][
		buf: as int-ptr! CGBitmapContextGetData bitmap
		buf: buf + index
		buf/value: color
		color
	]

	delete: func [img [red-image!]][
		CGContextRelease as-integer img/node
	]

	resize: func [
		img		[red-image!]
		width	[integer!]
		height	[integer!]
		return: [integer!]
		/local
			graphic [integer!]
			old-w	[integer!]
			old-h	[integer!]
			format	[integer!]
			bitmap	[integer!]
	][
		old-w: IMAGE_WIDTH(img/size)
		old-h: IMAGE_HEIGHT(img/size)

		graphic: 0
		format: 0
		bitmap: 0
		as-integer img/node
	]

	copy: func [
		dst		[integer!]
		src		[integer!]
		bytes	[integer!]
		offset	[integer!]
		/local
			dst-buf [byte-ptr!]
			src-buf [byte-ptr!]
	][
		dst-buf: CGBitmapContextGetData dst
		src-buf: CGBitmapContextGetData src
		copy-memory dst-buf src-buf + offset bytes
	]

	load-binary: func [
		data	[byte-ptr!]
		len		[integer!]
		return: [integer!]
		/local
			color-space [integer!]
			width		[integer!]
			height		[integer!]
			ctx			[integer!]
			rect		[NSRect!]
			bytes-row	[integer!]
			src			[integer!]
			image-data	[integer!]
			image		[integer!]
	][
		src: CFDataCreate 0 data len
		image-data: CGImageSourceCreateWithData src 0
		image: CGImageSourceCreateImageAtIndex image-data 0 0

		color-space: CGColorSpaceCreateDeviceRGB
		width: CGImageGetWidth image
		height: CGImageGetHeight image
		bytes-row: width * 4

		rect: make-rect 0 0 width height
		ctx: CGBitmapContextCreate null width height 8 bytes-row color-space kCGImageFormatARGB
		CGContextDrawImage ctx rect/x rect/y rect/w rect/h image

		CGColorSpaceRelease color-space
		CGImageRelease image
		CFRelease src
		CFRelease image-data
		ctx
	]

	load-image: func [
		filename	[c-string!]
		return:		[integer!]
		/local
			data	[byte-ptr!]
			size	[integer!]
			bmp		[integer!]
	][
		size: 0
		data: null
		;data: simple-io/read-data filename :size yes
		if null? data [return -1]

		bmp: load-binary data size
		free data
		bmp
	]

	make-image: func [
		width	[integer!]
		height	[integer!]
		rgb		[byte-ptr!]
		alpha	[byte-ptr!]
		color	[red-tuple!]
		return: [integer!]
		/local
			a			[integer!]
			r			[integer!]
			b			[integer!]
			g			[integer!]
			x			[integer!]
			y			[integer!]
			scan0		[int-ptr!]
			ctx			[integer!]
			pos			[integer!]
			color-space [integer!]
			bytes-row	[integer!]
	][
		color-space: CGColorSpaceCreateDeviceRGB
		bytes-row: width * 4
		ctx: CGBitmapContextCreate null width height 8 bytes-row color-space kCGImageFormatARGB
		CGColorSpaceRelease color-space
		scan0: as int-ptr! CGBitmapContextGetData ctx

		y: 0
		either null? color [
			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					either null? alpha [a: 255][a: 255 - as-integer alpha/1 alpha: alpha + 1]
					either null? rgb [r: 255 g: 255 b: 255][
						r: as-integer rgb/1
						g: as-integer rgb/2
						b: as-integer rgb/3
						rgb: rgb + 3
					]
					scan0/pos: r << 16 or (g << 8) or b or (a << 24)
					x: x + 1
				]
				y: y + 1
			]
		][
			r: color/array1
			a: either TUPLE_SIZE?(color) = 3 [255][255 - (r >>> 24)]
			r: r >> 16 and FFh or (r and FF00h) or (r and FFh << 16) or (a << 24)
			while [y < height][
				x: 0
				while [x < width][
					pos: width * y + x + 1
					scan0/pos: r
					x: x + 1
				]
				y: y + 1
			]
		]
		ctx
	]

	encode: func [
		image	[red-image!]
		format	[integer!]
		slot	[red-value!]
		return: [red-binary!]
		/local
			bin		[red-binary!]
	][
		bin: as red-binary! slot
		bin
	]

	clone: func [
		src		[red-image!]
		dst		[red-image!]
		part	[integer!]
		size	[red-pair!]
		part?	[logic!]
		return: [red-image!]
		/local
			x		[integer!]
			y		[integer!]
			w		[integer!]
			h		[integer!]
			offset	[integer!]
			handle	[integer!]
			width	[integer!]
			height	[integer!]
			bmp		[integer!]
			format	[integer!]
	][
		width: IMAGE_WIDTH(src/size)
		height: IMAGE_WIDTH(src/size)
		offset: src/head
		x: offset % width
		y: offset / width
		handle: as-integer src/node
		bmp: 0

		dst/header: TYPE_IMAGE
		dst/head: 0
		dst/node: as node! bmp
		dst
	]
]
