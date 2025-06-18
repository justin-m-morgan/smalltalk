import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

export default {
  mounted() {
    const height = this.el.clientHeight;
    const width = this.el.clientWidth;
    const clock = new THREE.Clock();
    clock.start();

    console.table({ height, width });

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(4, width / height, 0.1, 500);
    camera.position.z = 1;
    camera.position.y = 0.022;

    // const controls = new OrbitControls(camera, renderer.domElement);
    // controls.enableDampening = true;

    const hemiLight = new THREE.HemisphereLight(0xffffff, 0xdddddd);
    scene.add(hemiLight);

    const renderer = new THREE.WebGLRenderer({ alpha: true });
    renderer.setSize(width, height);

    this.el.appendChild(renderer.domElement);

    const loader = new GLTFLoader();

    loader
      .loadAsync("/models/lips_and_smile_mouth-v1-uncompressed.glb")
      .then((model) => {
        model.scene;
        scene.add(model.scene);
        function animate() {
          model.scene.rotation.x = Math.cos(clock.getElapsedTime()) * 0.2;
          model.scene.rotation.y = Math.sin(clock.getElapsedTime()) * 0.4;

          renderer.render(scene, camera);
        }
        renderer.setAnimationLoop(animate);
      });
  },
};
