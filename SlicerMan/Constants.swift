//
//  Constants.swift
//  SlicerMan
//
//  Created by Atin Agnihotri on 23/08/21.
//

import Foundation
import CoreGraphics

class Constants {
    public static let CENTER_POINT = CGPoint(x: 512, y: 384)
    public static let CENTER_X: CGFloat = 512
    public static let CENTER_Y: CGFloat = 384
    public static let QUARTER_X: CGFloat = 256
    public static let THREE_QUARTER_X: CGFloat = 768
    public static let ENEMY_X_MIN = 64
    public static let ENEMY_X_MAX = 960
    public static let ENEMY_Y = -128
    public static let ENEMY_ANG_MIN: CGFloat = -3
    public static let ENEMY_ANG_MAX: CGFloat = 3
    public static let ENEMY_VEL_CENTER_MIN = 3
    public static let ENEMY_VEL_CENTER_MAX = 5
    public static let ENEMY_VEL_EDGES_MIN = 8
    public static let ENEMY_VEL_EDGES_MAX = 15
    public static let ENEMY_Y_VEL_MIN = 24
    public static let ENEMY_Y_VEL_MAX = 32
    public static let ENEMY_FAST_Y_VEL_MIN = 36
    public static let ENEMY_FAST_Y_VEL_MAX = 44
    public static let ENEMY_VEL_FACTOR = 40
    public static let ENEMY_FAST_VEL_FACTOR = 60
    public static let EMITTER_X = 76
    public static let EMITTER_Y = 64
    public static let BOMB_TYPE = 0
    public static let FAST_MOVER_TYPE = 6
    public static let PHYSICS_BODY_RADIUS: CGFloat = 64
    public static let POPUP_DECREASE_FACTOR = 0.991
    public static let CHAIN_DELAY_DECREASE_FACTOR = 0.99
    public static let SIMULATION_SPEED_INCREASE_FACTOR: CGFloat = 1.02
    
    
//    public static let SPEED = 1000
//    public static let SPEED = 1000
//    public static let SPEED = 1000
}
