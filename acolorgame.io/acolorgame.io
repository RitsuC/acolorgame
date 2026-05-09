<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>A Color Game</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; }

    body {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: flex-end;
      background: #8fc4cc;
    }

    .bg {
      position: fixed;
      inset: 0;
      background-image: url('bg_0.png');
      background-size: cover;
      background-position: center;
      z-index: 0;
    }

    .buttons-container {
      position: relative;
      z-index: 1;
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: center;
      gap: 32px;
      padding-bottom: 48px;
      flex-wrap: wrap;
    }

    .btn {
      display: block;
      cursor: pointer;
      transition: transform 0.18s cubic-bezier(.34,1.56,.64,1), filter 0.18s ease;
      text-decoration: none;
      border: none;
      background: none;
      padding: 0;
    }

    .btn:hover {
      transform: scale(1.07) translateY(-4px);
      filter: brightness(1.08) drop-shadow(0 8px 24px rgba(0,0,0,0.18));
    }

    .btn:active {
      transform: scale(0.97) translateY(1px);
      filter: brightness(0.95);
    }

    .btn img {
      height: 72px;
      width: auto;
      display: block;
    }

    #scratch-canvas {
      position: fixed;
      inset: 0;
      z-index: 10;
      touch-action: none;
      cursor: crosshair;
    }

    @media (max-width: 600px) {
      .buttons-container { flex-direction: column; gap: 20px; padding-bottom: 36px; }
      .btn img { height: 56px; }
    }
  </style>
</head>
<body>
  <div class="bg"></div>

  <div class="buttons-container">
    <a class="btn" id="btn1" href="https://ritttsu.itch.io/" target="_blank" rel="noopener">
      <img src="btn_playthegame.png" alt="Play the game" />
    </a>
    <a class="btn" id="btn2" href="https://www.youtube.com/@Ritttsu37" target="_blank" rel="noopener">
      <img src="btn_devlog.png" alt="Watch the devlog" />
    </a>
    <a class="btn" id="btn3" href="https://discord.gg/EJ246FPc2g" target="_blank" rel="noopener">
      <img src="btn_discord.png" alt="Join our Discord" />
    </a>
  </div>

  <canvas id="scratch-canvas"></canvas>

  <script>
    const canvas = document.getElementById('scratch-canvas');
    const ctx = canvas.getContext('2d');
    const BRUSH_SIZE = 48;

    // Offscreen mask canvas — tracks scratched areas without reading pixel data
    // from the main canvas (avoids SecurityError entirely)
    const mask = document.createElement('canvas');
    const mctx = mask.getContext('2d');

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      mask.width = canvas.width;
      mask.height = canvas.height;
      drawCover();
    }

    const coverImg = new Image();
    // No crossOrigin needed — we never call getImageData on the main canvas
    coverImg.src = 'drawingcover.png';
    coverImg.onload = resize;
    coverImg.onerror = resize;

    function drawCover() {
      ctx.globalCompositeOperation = 'source-over';
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      if (coverImg.complete && coverImg.naturalWidth > 0) {
        // Replicate CSS background-size:cover + background-position:center
        const iw = coverImg.naturalWidth, ih = coverImg.naturalHeight;
        const cw = canvas.width, ch = canvas.height;
        const scale = Math.max(cw / iw, ch / ih);
        const dw = iw * scale, dh = ih * scale;
        const dx = (cw - dw) / 2, dy = (ch - dh) / 2;
        ctx.drawImage(coverImg, dx, dy, dw, dh);
      }
      // Reset mask to fully opaque (covered)
      mctx.fillStyle = '#000';
      mctx.fillRect(0, 0, mask.width, mask.height);
    }

    window.addEventListener('resize', resize);

    function scratch(x, y) {
      // Erase from visible canvas
      ctx.globalCompositeOperation = 'destination-out';
      ctx.beginPath();
      ctx.arc(x, y, BRUSH_SIZE, 0, Math.PI * 2);
      ctx.fill();

      // Mirror erase on mask canvas
      mctx.globalCompositeOperation = 'destination-out';
      mctx.beginPath();
      mctx.arc(x, y, BRUSH_SIZE, 0, Math.PI * 2);
      mctx.fill();
    }

    // Returns true if the mask pixel is transparent (i.e. scratched open)
    // The mask canvas only ever has our own drawn content — never tainted
    function isScratched(x, y) {
      const alpha = mctx.getImageData(x, y, 1, 1).data[3];
      return alpha < 64;
    }

    function forwardClick(x, y) {
      canvas.style.pointerEvents = 'none';
      const el = document.elementFromPoint(x, y);
      canvas.style.pointerEvents = 'auto';
      if (el && el !== canvas) {
        el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
      }
    }

    // Track whether mouse moved significantly (drag vs click)
    let isDown = false;
    let downX = 0, downY = 0;

    canvas.addEventListener('mousedown', (e) => {
      isDown = true;
      downX = e.clientX;
      downY = e.clientY;
      scratch(e.clientX, e.clientY);
    });

    canvas.addEventListener('mousemove', (e) => {
      if (!isDown) return;
      scratch(e.clientX, e.clientY);
    });

    window.addEventListener('mouseup', () => { isDown = false; });

    canvas.addEventListener('click', (e) => {
      const moved = Math.abs(e.clientX - downX) + Math.abs(e.clientY - downY);
      if (moved < 5 && isScratched(e.clientX, e.clientY)) {
        forwardClick(e.clientX, e.clientY);
      }
    });

    // Touch
    let touchStartX = 0, touchStartY = 0;

    canvas.addEventListener('touchstart', (e) => {
      e.preventDefault();
      isDown = true;
      const t = e.touches[0];
      touchStartX = t.clientX;
      touchStartY = t.clientY;
      scratch(t.clientX, t.clientY);
    }, { passive: false });

    canvas.addEventListener('touchmove', (e) => {
      e.preventDefault();
      if (!isDown) return;
      const t = e.touches[0];
      scratch(t.clientX, t.clientY);
    }, { passive: false });

    canvas.addEventListener('touchend', (e) => {
      isDown = false;
      const t = e.changedTouches[0];
      const moved = Math.abs(t.clientX - touchStartX) + Math.abs(t.clientY - touchStartY);
      if (moved < 5 && isScratched(t.clientX, t.clientY)) {
        forwardClick(t.clientX, t.clientY);
      }
    });
  </script>
</body>
</html>
