set_volume! 1
set :takt, 0
set_sched_ahead_time! 1
use_bpm 96
use_random_seed 9
define :pfad do |name|
  "/Users/[... your folder ...]" + name + ".wav"
end
define :fx_pfad do |name| pfad(name) end
define :vox_pfad do |name| pfad(name) end
alle_samples = ["effect_rain", "effect_craw",
                "vocal_in_limine_1", "vocal_in_limine_2",
                "vocal_vale", "vocal_in_limine_puls",
                "vocal_crux_sacra", "vocal_exorcizamus_te",
                "vocal_in_nomine", "vocal_adjura_me"]
fehlend = alle_samples.reject { |n| File.exist?(pfad(n)) }
unless fehlend.empty?
  fehlend.each { |n| puts "FEHLT: " + pfad(n) }
  raise "Es fehlen #{fehlend.length} Sample-Datei(en) - siehe Log"
end
alle_samples.each { |n| load_sample pfad(n) }
puts "ALLE #{alle_samples.length} SAMPLES GELADEN"
sample pfad("vocal_crux_sacra"), rate: 0.7, amp: 0.4
sample pfad("effect_craw"), rate: 0.8, amp: 0.6
live_loop :puls do
  stop if takt >= schluss
  tick
  set :takt, look
  sleep 4
end
define :takt do
  get(:takt) || 0
end
define :schluss do 104 end
define :refrain? do
  ((takt >= 32) && (takt < 40)) ||
    ((takt >= 64) && (takt < 72)) ||
    ((takt >= 88) && (takt < 96))
end
define :breakdown? do (takt >= 56) && (takt < 64) end
define :marsch? do (takt >= 16) && (takt < 96) && !breakdown? end
define :finale? do takt >= 96 end
define :akkord_beben do
  if refrain?
    (ring :c3, :g2, :d3, :e3)[takt % 4]
  else
    (ring :e3, :c3, :d3, :b2, :a2, :e3, :c3, :b2)[takt % 8]
  end
end
define :akkord_grund do
  if refrain?
    (ring :c1, :g1, :d1, :e1)[takt % 4]
  else
    (ring :e1, :c1, :d1, :b0, :a1, :e1, :c1, :b0)[takt % 8]
  end
end
live_loop :abblende, sync: :puls do
  stop if takt >= schluss
  if finale?
    set_volume! [1.0 - 0.09 * (takt - 96), 0.35].max
  end
  sleep 4
end
with_fx :lpf, cutoff: 95 do
  live_loop :beben, sync: :puls do
    stop if takt >= schluss
    use_synth :dsaw
    n = akkord_beben
    laut = (takt < 8 ? 0.7 : 1.0)
    16.times do |i|
      play n, release: 0.3, cutoff: 85, detune: 0.3,
        amp: (i.even? ? 0.3 : 0.22) * laut
      play note(n) + 7, release: 0.3, cutoff: 80,
        detune: 0.35, amp: 0.16 * laut
      sleep 0.25
    end
  end
end
live_loop :grund, sync: :puls do
  stop if takt >= schluss
  if takt >= 8
    use_synth :fm
    n = akkord_grund
    if breakdown?
      play n, divisor: 1, depth: 1.0, release: 2.5,
        cutoff: 60, amp: 1.0
      sleep 4
    else
      play n, divisor: 1, depth: 1.2, release: 1.2,
        cutoff: 70, amp: 1.4
      sleep 2.5
      play n, divisor: 1, depth: 1.2, release: 0.8,
        cutoff: 65, amp: 1.0
      sleep 1.5
    end
  else
    sleep 4
  end
end
live_loop :schlag, sync: :puls do
  stop if takt >= schluss
  if marsch?
    sample :bd_haus, amp: 1.1, lpf: 85
    sleep 2
    sample :sn_dolf, amp: 0.5, rate: 0.9, lpf: 95
    sample :perc_snap, amp: 0.3, rate: 0.8
    sleep 2
  else
    sleep 4
  end
end
live_loop :hauch, sync: :puls do
  stop if takt >= schluss
  if (takt >= 8) && (takt < 96) && !breakdown?
    sleep 0.5
    sample :drum_cymbal_closed, amp: 0.18, rate: 0.85, lpf: 90
    sleep 0.5
  else
    sleep 4
  end
end
with_fx :reverb, room: 0.9, mix: 0.55 do
  live_loop :oberstimme, sync: :puls do
    stop if takt >= schluss
    if refrain?
      use_synth :prophet
      ton = (ring :e5, :d5, :fs5, :e5)[takt % 4]
      play ton, attack: 0.5, sustain: 2.5, release: 1.5,
        cutoff: 90, amp: 0.4
      sleep 4
    else
      sleep 4
    end
  end
end
with_fx :hpf, cutoff: 85 do
  with_fx :reverb, room: 0.9, mix: 0.5 do
    live_loop :chor, sync: :puls do
      stop if takt >= schluss
      if (takt >= 16) && (one_in(2) || breakdown?)
        anfang = rrand(0.1, 0.6)
        sample :ambi_choir, rate: 0.85, start: anfang,
          finish: [anfang + 0.25, 1.0].min,
          amp: (breakdown? ? 0.55 : 0.4)
      end
      sleep 8
    end
  end
end
define :regenpegel do
  t = takt
  if (t >= 48) && (t < 56)
    0.3 * (t - 48) / 8.0
  elsif (t >= 56) && (t < 64)
    0.3
  elsif (t >= 64) && (t < 70)
    0.3 * (70 - t) / 6.0
  elsif (t >= 88) && (t < 96)
    0.4 * (t - 88) / 8.0
  elsif t >= 96
    0.4
  else
    0
  end
end
live_loop :regen, sync: :puls do
  stop if takt >= schluss
  pegel = regenpegel
  if pegel > 0.005
    sample fx_pfad("effect_rain"), amp: pegel * 0.6, attack: 3
  end
  sleep 4
end
with_fx :reverb, room: 0.9, mix: 0.5 do
  live_loop :stimme, sync: :puls do
    stop if takt >= schluss
    case takt
    when 5
      sample fx_pfad("effect_craw"), rate: [0.9, 0.75].choose, amp: 0.5
    when 22
      sample vox_pfad("vocal_exorcizamus_te"), rate: 0.8,
        amp: 0.85, lpf: 100
    when 28
      sample vox_pfad("vocal_crux_sacra"), rate: 0.6, amp: 0.6
      sample fx_pfad("effect_craw"), rate: 0.75, amp: 0.5
    when 44
      sample vox_pfad("vocal_in_limine_1"), rate: 0.7, amp: 1.0
    when 50
      sample vox_pfad("vocal_in_nomine"), rate: 0.6, amp: 0.6, lpf: 95
    when 57
      sample vox_pfad("vocal_in_limine_2"), rate: 0.75, amp: 1.05
    when 74
      sample vox_pfad("vocal_crux_sacra"), rate: 0.5, amp: 0.6
      sample fx_pfad("effect_craw"), rate: 0.85, amp: 0.5
    when 78
      sample vox_pfad("vocal_adjura_me"), rate: 0.55, amp: 0.65, lpf: 90
    when 88
      sample vox_pfad("vocal_in_limine_puls"), rate: 0.8,
        amp: 0.65, hpf: 70
    when 100
      sample vox_pfad("vocal_vale"), rate: 0.8, amp: 0.8
    end
    sleep 4
  end
end
live_loop :letzter_ton, sync: :puls do
  if takt >= schluss
    set_volume! 0.5
    sleep 1
    with_fx :reverb, room: 1, mix: 0.8 do
      use_synth :prophet
      play :e4, attack: 1, sustain: 3, release: 6, cutoff: 85, amp: 0.5
      play :b4, attack: 1.5, sustain: 2.5, release: 6, cutoff: 80, amp: 0.35
      synth :sine, note: :e2, attack: 0.5, sustain: 3, release: 8, amp: 0.4
    end
    stop
  end
  sleep 4
end
