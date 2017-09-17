//
//  ViewController.swift
//  ARKit6-射击
//
//  Created by 刘文 on 2017/9/14.
//  Copyright © 2017年 刘文. All rights reserved.
//

import ARKit

enum BitMaskCategory: Int {
    case bullet = 2
    case egg = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var target: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(fireHandle(tapGes:)))
        sceneView.addGestureRecognizer(tapGes)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        sceneView.session.run(config)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @IBAction func addTargets(_ sender: Any) {
        addEgg(x: 5, y: 0, z: -40)
        addEgg(x: 0, y: 0, z: -40)
        addEgg(x: -5, y: 0, z: -40)
    }
    
    func addEgg(x: Float, y: Float, z: Float) {
        if let egg = SCNScene(named: "Media.scnassets/egg.scn")?.rootNode.childNode(withName: "egg", recursively: false) {
            egg.position = SCNVector3(x,y,z)
            
//            egg.physicsBody = SCNPhysicsBody.static()
            egg.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: egg, options: nil))
            egg.physicsBody?.categoryBitMask = BitMaskCategory.egg.rawValue // 类别位掩码
            egg.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue // 接触测试位掩码
            sceneView.scene.rootNode.addChildNode(egg)
        }
    }
    
    @objc func fireHandle(tapGes: UITapGestureRecognizer) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33) // 物件方向
        let location = SCNVector3(-transform.m41, -transform.m42, -transform.m43) // 本地方向
        
        let position = orientation + location // 成功地拿到子彈要射向的位置
        
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bullet.position = position
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
        physicsBody.isAffectedByGravity = false
        physicsBody.applyForce(SCNVector3(orientation.x * 50,orientation.y * 50,orientation.z * 50), asImpulse: true)
        
        physicsBody.categoryBitMask = BitMaskCategory.bullet.rawValue
        physicsBody.contactTestBitMask = BitMaskCategory.egg.rawValue
        
        bullet.physicsBody = physicsBody
        
        sceneView.scene.rootNode.addChildNode(bullet)
    }

    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        print("physicsWorld didBegin")
        
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        // 如果 nodeA 是蛋
        if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.egg.rawValue {
            self.target = nodeA
        } else {
            self.target = nodeB
        }
        
        let confetti = SCNParticleSystem(named: "Media.scnassets/Fire.scnp", inDirectory: nil)
        confetti?.loops = false
        confetti?.particleLifeSpan = 4
        confetti?.emitterShape = target?.geometry //几何
        
        // 粒子动画
        let confettiNode = SCNNode()
        confettiNode.addParticleSystem(confetti!)
//        confettiNode.position = contact.contactPoint
        confettiNode.position = target!.position
        self.sceneView.scene.rootNode.addChildNode(confettiNode)
        
        target?.removeFromParentNode()
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}


