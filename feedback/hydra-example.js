r = 0.2
g = 0.5
b = 0.6
brightv = 0.4
osc(12,0.2,1)
  .kaleid()
  .mask(shape(4,0.3,1))
  .modulateRotate(shape(4,0.1,1))
  .modulateRotate(shape(4,0.1,0.9))
  .modulateRotate(shape(4,0.1,0.8))
  .scale(0.22)
  .add(shape(4,0.2,1).color(
    () => r,() => g,() => b))
  .brightness(() => brightv)
  .rotate(()=>time*0.3)
  .out()

msg.setPort(3336)
msg.on('/hydra/color', (args) => {
  r = args[0];
  g = args[1];
  b = args[2];
  console.log(args);
})
msg.on('/hydra/brightness', (args) => {
  brightv = args[0];
  console.log(args);
})

