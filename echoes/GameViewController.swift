import UIKit
import SceneKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var gameScene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the SCNView
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)
        
        // Set up the GameScene
        gameScene = GameScene()
        scnView.scene = gameScene

        // Configure the SCNView
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
