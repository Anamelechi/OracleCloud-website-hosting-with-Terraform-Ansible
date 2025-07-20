// Magic Mouse effect: a glowing orb smoothly follows the cursor with a trailing effect
(function () {
  const magicMouse = document.getElementById("magicMouse");
  let targetX = 0,
      targetY = 0,
      currentX = 0,
      currentY = 0;
  const speed = 0.1; // Adjust for trailing smoothness

  document.addEventListener("mousemove", (e) => {
    targetX = e.clientX;
    targetY = e.clientY;
  });

  function animate() {
    // Move the current position toward the target (mouse) position
    currentX += (targetX - currentX) * speed;
    currentY += (targetY - currentY) * speed;
    // Update the magic mouse position (center it by subtracting half its size)
    magicMouse.style.transform = `translate(${currentX}px, ${currentY}px)`;
    requestAnimationFrame(animate);
  }
  animate();
})();