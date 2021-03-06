import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var hud: MBProgressHUD!
    
    private var currentAngleY: Float = 0.0
    private var newAngleY: Float = 0.0
    private var localTranslationPosition: CGPoint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.autoenablesDefaultLighting = true
        
        self.hud = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
        
        self.hud.label.text = "Detecting plane..."
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    // Fired when a plane is detected
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            DispatchQueue.main.async {
                self.hud.label.text = "Plane detected!"
                self.hud.hide(animated: true, afterDelay: 1.0)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}

// Gesture Recognizers: Tapping, Pinching, Panning
extension ViewController {
    private func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func tapped(recognizer: UITapGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touch, types: .existingPlane)
        
        if let hitTest = hitTestResults.first {
            guard let chairScene = SCNScene(named: "chair.dae"),
                let chairNode = chairScene.rootNode.childNode(withName: "parentNode", recursively: true) else { return }
            
            // Gets the position of the touch in the 3D coordinate plane
            chairNode.position = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z)
            
            self.sceneView.scene.rootNode.addChildNode(chairNode)
        }
    }
    
    @objc private func pinched(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .changed {
            guard let sceneView = recognizer.view as? ARSCNView else { return }
            
            let touch = recognizer.location(in: sceneView)
            let hitTestResults = self.sceneView.hitTest(touch, options: nil)
            
            if let hitTest = hitTestResults.first {
                let chairNode = hitTest.node
                let pinchScaleX = Float(recognizer.scale) * chairNode.scale.x
                let pinchScaleY = Float(recognizer.scale) * chairNode.scale.y
                let pinchScaleZ = Float(recognizer.scale) * chairNode.scale.z
                
                chairNode.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
                
                recognizer.scale = 1
            }
            
        }
    }
    
    @objc private func panned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            guard let sceneView = recognizer.view as? ARSCNView else { return }
            
            let touch = recognizer.location(in: sceneView)
            let translation = recognizer.translation(in: sceneView)
            let hitTestResults = self.sceneView.hitTest(touch, options: nil)
            
            if let hitTest = hitTestResults.first {
                if let parentNode = hitTest.node.parent {
                    // Just grabbing the translation.x makes it so that the object can only be rotated horizontally.
                    // If you investigate the eulerAngles in the chair.dae file, you will see how the eulerAngles affect
                    // the rotation of the chair.
                    self.newAngleY = Float(translation.x) * Float(Double.pi / 180)
                    self.newAngleY += self.currentAngleY
                    parentNode.eulerAngles.y = self.newAngleY
                }
            }
        case .ended:
            self.currentAngleY = self.newAngleY
        default:
            return
        }
    }
    
    @objc private func longPressed(recognizer: UILongPressGestureRecognizer) {
        guard let sceneView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: sceneView)
        let hitTestResults = self.sceneView.hitTest(touch, options: nil)
        
        if let hitTest = hitTestResults.first {
            if let parentNode = hitTest.node.parent {
                switch recognizer.state {
                case .began:
                    localTranslationPosition = touch
                case .changed:
                    let deltaX = Float(touch.x - localTranslationPosition.x) / 700
                    let deltaY = Float(touch.y - localTranslationPosition.y) / 700
                    
                    parentNode.localTranslate(by: SCNVector3(deltaX, 0.0, deltaY))
                    self.localTranslationPosition = touch
                default:
                    return
                }
            }
        }
    }
}
