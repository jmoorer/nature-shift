// Core game engine and prototype logic
import { NATURE_CONFIG, ABILITY_CATALOG, ENEMY_CONFIG, PLAYER_CONFIG } from './config.js';

class Game {
  constructor() {
    this.canvas = document.getElementById('gameCanvas');
    this.ctx = this.canvas.getContext('2d');
    this.width = this.canvas.width = window.innerWidth;
    this.height = this.canvas.height = window.innerHeight;
    
    // Game state
    this.player = null;
    this.enemies = [];
    this.abilities = {};
    this.conductivePools = [];
    this.particleEffects = [];
    this.score = 0;
    this.gameOver = false;
    this.lastTime = 0;
    this.clockTime = 0;
    
    // Input state
    this.keys = {};
    this.mouse = { x: 0, y: 0 };
    this.mouseDown = false;
    
    // Initialize game
    this.initializeInput();
    this.initializeAbilities();
    this.spawnPlayer();
    this.spawnEnemy();
    
    // Start game loop
    this.lastTime = performance.now();
    requestAnimationFrame(this.gameLoop.bind(this));
  }
  
  initializeInput() {
    // Keyboard input
    window.addEventListener('keydown', (e) => {
      this.keys[e.key.toLowerCase()] = true;
      e.preventDefault();
    });
    window.addEventListener('keyup', (e) => {
      this.keys[e.key.toLowerCase()] = false;
      e.preventDefault();
    });
    
    // Mouse input
    this.canvas.addEventListener('mousemove', (e) => {
      this.mouse.x = e.clientX;
      this.mouse.y = e.clientY;
    });
    this.canvas.addEventListener('mousedown', () => { this.mouseDown = true; });
    this.canvas.addEventListener('mouseup', () => { this.mouseDown = false; });
    
    // Restart key
    window.addEventListener('keydown', (e) => {
      if (e.key.toLowerCase() === 'r') this.restart();
    });
  }
  
  initializeAbilities() {
    const config = ABILITY_CATALOG;
    // Initialize ability cooldown timers
    Object.values(config).forEach(ability => {
      this.abilities[ability.id] = {
        ...ability,
        cooldown: 0,
        active: false,
        createdAt: 0
      };
    });
  }
  
  spawnPlayer() {
    this.player = {
      x: 100,
      y: this.height / 2,
      vx: 0,
      vy: 0,
      width: 24,
      height: 24,
      health: PLAYER_CONFIG.health,
      maxHealth: PLAYER_CONFIG.health,
      speed: PLAYER_CONFIG.speed,
      attackCooldown: 0,
      color: NATURE_CONFIG.elements.water.color
    };
  }
  
  spawnEnemy() {
    const enemyConfig = ENEMY_CONFIG.conductive_target;
    const side = Math.floor(Math.random() * 4);
    let x, y;
    
    switch (side) {
      case 0: x = -50; y = Math.random() * this.height; break;
      case 1: x = this.width + 50; y = Math.random() * this.height; break;
      case 2: x = Math.random() * this.width; y = -50; break;
      case 3: x = Math.random() * this.width; y = this.height + 50; break;
    }
    
    this.enemies.push({
      x,
      y,
      width: 32,
      height: 32,
      health: enemyConfig.health,
      maxHealth: enemyConfig.health,
      speed: enemyConfig.speed,
      aggroRange: enemyConfig.aggroRange,
      naturallyConductive: enemyConfig.naturallyConductive,
      isConductive: false,
      color: '#e53935',
      target: null,
      patrolDir: Math.random() > 0.5 ? 1 : -1
    });
  }
  
  updatePlayer(deltaTime) {
    const speed = this.player.speed * deltaTime / 16;
    const maxVel = 5 * deltaTime / 16;
    
    // Movement
    if (this.keys['w'] || this.keys['arrowup']) this.player.vy -= speed;
    if (this.keys['s'] || this.keys['arrowdown']) this.player.vy += speed;
    if (this.keys['a'] || this.keys['arrowleft']) this.player.vx -= speed;
    if (this.keys['d'] || this.keys['arrowright']) this.player.vx += speed;
    
    // Apply velocity with max speed
    const vel = Math.sqrt(this.player.vx * this.player.vx + this.player.vy * this.player.vy);
    if (vel > maxVel) {
      const scale = maxVel / vel;
      this.player.vx *= scale;
      this.player.vy *= scale;
    }
    
    // Update position
    this.player.x += this.player.vx;
    this.player.y += this.player.vy;
    
    // Screen boundaries
    this.player.x = Math.max(this.player.width/2, Math.min(this.width - this.player.width/2, this.player.x));
    this.player.y = Math.max(this.player.height/2, Math.min(this.height - this.player.height/2, this.player.y));
    
    // Reset velocity
    this.player.vx *= 0.92;
    this.player.vy *= 0.92;
  }
  
  updateEnemies(deltaTime) {
    for (const enemy of this.enemies) {
      // Determine target (player)
      const dx = this.player.x - enemy.x;
      const dy = this.player.y - enemy.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      
      if (dist < enemy.aggroRange) {
        // Move towards player
        const angle = Math.atan2(dy, dx);
        enemy.vx = Math.cos(angle) * enemy.speed * deltaTime / 16;
        enemy.vy = Math.sin(angle) * enemy.speed * deltaTime / 16;
        enemy.target = this.player;
        
        // Check for collision
        if (dist < 40) {
          this.takeDamage(this.player, 5 * deltaTime / 16);
          this.showFlash('hit');
        }
      } else {
        // Patrol behavior
        enemy.x += enemy.patrolDir * enemy.speed * deltaTime / 16;
        if (enemy.x < 50 || enemy.x > this.width - 50) {
          enemy.patrolDir *= -1;
        }
        enemy.target = null;
      }
      
      // Update position
      enemy.x += enemy.vx;
      enemy.y += enemy.vy;
      
      // Screen wrapping
      if (enemy.y < -50) enemy.y = this.height + 50;
      if (enemy.y > this.height + 50) enemy.y = -50;
    }
  }
  
  useAbility(abilityId) {
    const ability = this.abilities[abilityId];
    if (!ability) return;
    
    // Check if on cooldown
    const currentTime = performance.now() / 1000;
    if (ability.cooldown > currentTime) return;
    
    const config = ABILITY_CATALOG[abilityId];
    
    switch (abilityId) {
      case 'water_conductive_pool':
        this.createConductivePool(this.mouse.x, this.mouse.y, config.radius);
        break;
        
      case 'lightning_chain':
        if (this.mouseDown) {
          const enemy = this.getNearestEnemy(this.mouse.x, this.mouse.y);
          if (enemy) {
            this.fireLightningBolt(enemy, config.baseDamage);
          }
        }
        break;
    }
    
    // Start cooldown
    ability.cooldown = currentTime + config.cooldown;
    ability.active = true;
    ability.createdAt = currentTime;
  }
  
  createConductivePool(x, y, radius) {
    this.conductivePools.push({
      x,
      y,
      radius,
      createdAt: performance.now() / 1000,
      id: Date.now()
    });
    
    // Make enemies in range conductive
    for (const enemy of this.enemies) {
      const dx = enemy.x - x;
      const dy = enemy.y - y;
      if (dx * dx + dy * dy <= radius * radius) {
        enemy.isConductive = true;
        // Visual feedback for conductive effect
        this.particleEffects.push({
          x: enemy.x,
          y: enemy.y,
          type: 'conductive',
          createdAt: performance.now() / 1000
        });
      }
    }
  }
  
  fireLightningBolt(target, baseDamage) {
    this.particleEffects.push({
      x: this.mouse.x,
      y: this.mouse.y,
      target,
      damage: baseDamage,
      type: 'lightning_bolt',
      createdAt: performance.now() / 1000,
      chainActive: target.isConductive
    });
    
    // Show flash effect
    this.showFlash('hit');
    
    // If target was conductive, chain to nearby enemies
    if (target.isConductive) {
      this.chainLightning(target, baseDamage);
    }
  }
  
  chainLightning(sourceEnemy, damage) {
    const chainDamage = ABILITY_CATALOG.lightning_chain.chainDamage;
    
    for (const enemy of this.enemies) {
      if (enemy !== sourceEnemy && !enemy.dead) {
        const dx = sourceEnemy.x - enemy.x;
        const dy = sourceEnemy.y - enemy.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        
        if (dist < 150) {
          this.particleEffects.push({
            x: enemy.x,
            y: enemy.y,
            target: enemy,
            damage: chainDamage,
            type: 'lightning_chain',
            createdAt: performance.now() / 1000,
            chainActive: enemy.isConductive
          });
          this.takeDamage(enemy, chainDamage);
          this.showFlash('hit');
          break; // Chain to only one additional target per shot
        }
      }
    }
  }
  
  takeDamage(target, damage) {
    target.health = Math.max(0, target.health - damage);
    
    // Check for death
    if (target.health <= 0) {
      target.dead = true;
      if (target === this.player) {
        this.gameOver = true;
      }
    }
    
    // Visual feedback
    this.showFlash('hit');
  }
  
  showFlash(type) {
    const flash = document.getElementById('flash');
    if (type === 'hit') {
      flash.className = 'flash hit';
    } else {
      flash.className = 'flash miss';
    }
    setTimeout(() => {
      flash.className = 'flash';
    }, 300);
  }
  
  getNearestEnemy(x, y) {
    let nearest = null;
    let nearestDist = Infinity;
    
    for (const enemy of this.enemies) {
      if (enemy.dead) continue;
      
      const dx = enemy.x - x;
      const dy = enemy.y - y;
      const dist = dx * dx + dy * dy;
      
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = enemy;
      }
    }
    
    return nearest;
  }
  
  draw() {
    // Clear canvas
    this.ctx.fillStyle = NATURE_CONFIG.elements.water.color;
    this.ctx.fillRect(0, 0, this.width, this.height);
    
    // Draw player
    this.ctx.fillStyle = this.player.color;
    this.ctx.fillRect(this.player.x - this.player.width/2, this.player.y - this.player.height/2, 
                     this.player.width, this.player.height);
    
    // Draw enemies
    for (const enemy of this.enemies) {
      if (enemy.dead) continue;
      
      // Apply conductive effect visual
      const color = enemy.isConductive ? '#4a90e2' : enemy.color;
      this.ctx.fillStyle = color;
      this.ctx.fillRect(enemy.x - enemy.width/2, enemy.y - enemy.height/2, enemy.width, enemy.height);
      
      // Draw health bar
      const healthPercent = enemy.health / enemy.maxHealth;
      this.ctx.fillStyle = '#333';
      this.ctx.fillRect(enemy.x - enemy.width/2, enemy.y - enemy.height/2 - 10, enemy.width, 4);
      this.ctx.fillStyle = enemy.isConductive ? '#4a90e2' : '#e53935';
      this.ctx.fillRect(enemy.x - enemy.width/2, enemy.y - enemy.height/2 - 10, enemy.width * healthPercent, 4);
    }
    
    // Draw conductive pools
    for (const pool of this.conductivePools) {
      const age = performance.now() / 1000 - pool.createdAt;
      const alpha = age < 3.0 ? 1.0 : Math.max(0, 1.0 - (age - 3.0) / 2.0);
      
      this.ctx.strokeStyle = `rgba(74, 144, 226, ${alpha})`;
      this.ctx.lineWidth = 3;
      this.ctx.setLineDash([5, 5]);
      this.ctx.beginPath();
      this.ctx.arc(pool.x, pool.y, pool.radius, 0, Math.PI * 2);
      this.ctx.stroke();
      this.ctx.setLineDash([]);
      
      if (alpha > 0.3) {
        this.ctx.fillStyle = `rgba(74, 144, 226, ${alpha * 0.2})`;
        this.ctx.beginPath();
        this.ctx.arc(pool.x, pool.y, pool.radius, 0, Math.PI * 2);
        this.ctx.fill();
      }
    }
    
    // Draw particle effects
    for (let i = this.particleEffects.length - 1; i >= 0; i--) {
      const effect = this.particleEffects[i];
      const age = performance.now() / 1000 - effect.createdAt;
      
      if (age > 1.0) {
        this.particleEffects.splice(i, 1);
        continue;
      }
      
      if (effect.type === 'lightning_bolt') {
        // Draw lightning bolt (simplified)
        this.ctx.strokeStyle = '#f5e619';
        this.ctx.lineWidth = 2;
        this.ctx.beginPath();
        this.ctx.moveTo(this.mouse.x, this.mouse.y);
        if (effect.target) {
          this.ctx.lineTo(effect.target.x, effect.target.y);
        }
        this.ctx.stroke();
        
        // Chain effect if applicable
        if (effect.chainActive && age > 0.3) {
          this.ctx.strokeStyle = '#4a90e2';
          this.ctx.lineWidth = 1;
          this.ctx.beginPath();
          this.ctx.moveTo(effect.target.x, effect.target.y);
          // Draw small arc for chain visual
          this.ctx.arc(effect.target.x, effect.target.y, 30, 0, Math.PI * 2);
          this.ctx.stroke();
        }
      }
    }
    
    // Draw UI overlay
    this.drawUI();
  }
  
  drawUI() {
    // Player health bar
    const playerHealthPercent = this.player.health / this.player.maxHealth;
    const enemyHealthPercent = this.enemies.reduce((sum, e) => e.dead ? sum : sum + (e.health / e.maxHealth), 0) /
                              this.enemies.filter(e => !e.dead).length || 1;
    
    // Update UI elements
    document.getElementById('bar-player').style.width = (playerHealthPercent * 100) + '%';
    document.getElementById('bar-enemy').style.width = (enemyHealthPercent * 100) + '%';
    
    // Update status text
    document.getElementById('status-player').textContent = 
      this.player.health <= 0 ? 'DEFEATED' : 
      this.player.health < this.player.maxHealth * 0.5 ? 'LOW HEALTH' : 'HEALTHY';
    
    document.getElementById('status-enemy').textContent = 
      this.enemies.filter(e => !e.dead).length === 0 ? 'ALL DEFEATED' : 'PATROLLING';
    
    // Update ability cooldowns
    for (const [id, ability] of Object.entries(this.abilities)) {
      const config = ABILITY_CATALOG[id];
      const cdEl = document.getElementById(`ab-${id.split('_')[0]}`);
      if (!cdEl) continue;
      
      const currentTime = performance.now() / 1000;
      const remaining = ability.cooldown - currentTime;
      
      if (remaining > 0) {
        cdEl.classList.add('cd');
        // Update cooldown display
        if (id === 'water_conductive_pool' || id === 'lightning_chain') {
          const cdDisplay = document.getElementById(`cd-${id.split('_')[0]}`);
          if (cdDisplay) cdDisplay.textContent = Math.ceil(remaining);
        }
      } else {
        cdEl.classList.remove('cd');
      }
    }
    
    // Update hint
    const hintText = `Q: Water (Conductive Pool) | E: Lightning (Chain) | WASD: Move | R: Restart`;
    document.getElementById('hint').textContent = hintText;
  }
  
  update(deltaTime) {
    if (this.gameOver) {
      this.updateGameOver();
      return;
    }
    
    // Update game clock
    this.clockTime += deltaTime / 1000;
    
    // Update game objects
    this.updatePlayer(deltaTime);
    this.updateEnemies(deltaTime);
    
    // Clean up old conductive pools
    this.conductivePools = this.conductivePools.filter(pool => {
      const age = this.clockTime - pool.createdAt;
      return age < 5.0;
    });
    
    // Reset mouse click state
    this.mouseDown = false;
    
    // Handle ability inputs
    if (this.keys['q']) this.useAbility('water_conductive_pool');
    if (this.keys['e']) this.useAbility('lightning_chain');
  }
  
  updateGameOver() {
    // Display game over screen
    this.ctx.fillStyle = 'rgba(0,0,0,0.7)';
    this.ctx.fillRect(0, 0, this.width, this.height);
    this.ctx.fillStyle = '#fff';
    this.ctx.font = '32px monospace';
    this.ctx.textAlign = 'center';
    this.ctx.fillText('GAME OVER', this.width/2, this.height/2 - 30);
    this.ctx.font = '20px monospace';
    this.ctx.fillText('Press R to Restart', this.width/2, this.height/2 + 10);
    this.ctx.fillText(`Score: ${this.score}`, this.width/2, this.height/2 + 40);
  }
  
  restart() {
    // Reset game state
    this.player = null;
    this.enemies = [];
    this.conductivePools = [];
    this.particleEffects = [];
    this.score = 0;
    this.gameOver = false;
    this.clockTime = 0;
    
    // Reinitialize
    this.initializeAbilities();
    this.spawnPlayer();
    this.spawnEnemy();
  }
  
  gameLoop(timestamp) {
    const deltaTime = timestamp - this.lastTime;
    this.lastTime = timestamp;
    
    this.update(deltaTime);
    this.draw();
    
    requestAnimationFrame(this.gameLoop.bind(this));
  }
}

// Start the game when the page loads
window.addEventListener('load', () => {
  new Game();
});