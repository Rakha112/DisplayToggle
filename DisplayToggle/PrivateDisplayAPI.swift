//
//  PrivateDisplayAPI.swift
//  DisplayToggle
//
//  Created by Rakha Wibowo on 18/09/25.
//

import CoreGraphics

@_silgen_name("CGSConfigureDisplayEnabled")
func CGSConfigureDisplayEnabled(
    _ config: CGDisplayConfigRef?,
    _ display: CGDirectDisplayID,
    _ enable: Bool)
-> CGError

@_silgen_name("CGSGetDisplayList")
internal func CGSGetDisplayList(
    _ maxDisplays: CInt,
    _ onlineDisplays: UnsafeMutablePointer<CGDirectDisplayID>?,
    _ displayCount: UnsafeMutablePointer<CInt>?
) -> CGError
