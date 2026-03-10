import { useRef, useState, type ReactNode } from 'react';

interface GlowCardProps {
  children: ReactNode;
  className?: string;
  glowColor?: string;
}

const GlowCard: React.FC<GlowCardProps> = ({
  children,
  className = '',
  glowColor = 'rgba(16, 163, 127, 0.5)',
}) => {
  const cardRef = useRef<HTMLDivElement>(null);
  const [glowStyle, setGlowStyle] = useState<React.CSSProperties>({});

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!cardRef.current) return;
    const rect = cardRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    setGlowStyle({
      background: `radial-gradient(250px circle at ${x}px ${y}px, ${glowColor}, transparent 70%)`,
      opacity: 1,
    });
  };

  const handleMouseLeave = () => {
    setGlowStyle({ opacity: 0 });
  };

  return (
    <div
      ref={cardRef}
      className={`relative overflow-hidden ${className}`}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
    >
      {/* Border glow layer */}
      <div
        className="pointer-events-none absolute inset-0 rounded-[inherit] transition-opacity duration-300"
        style={glowStyle}
      />
      {/* Mask out the inside so only the border glows */}
      <div
        className="pointer-events-none absolute inset-0 rounded-[inherit] transition-opacity duration-300"
        style={{
          ...glowStyle,
          mask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
          maskComposite: 'exclude',
          WebkitMaskComposite: 'xor',
          padding: '1px',
        }}
      />
      {/* Content */}
      <div className="relative z-10">{children}</div>
    </div>
  );
};

export default GlowCard;
