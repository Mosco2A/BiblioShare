import { useState } from "react";

const colors = {
  primary: "#8B6F4E",
  primaryLight: "#C4956A",
  primaryDark: "#5C4033",
  secondary: "#A67B5B",
  accent: "#D4A574",
  background: "#FFF8F0",
  backgroundWarm: "#FFF5EB",
  surface: "#FFFFFF",
  surfaceWarm: "#F5E6D3",
  text: "#3D2B1F",
  textMuted: "#7A6555",
  textLight: "#A69585",
  border: "#E8D5C0",
  borderLight: "#F0E4D4",
  success: "#7B9E6B",
  error: "#C4716C",
  warning: "#D4A04A",
};

const BookIcon = ({ size = 24, color = colors.primary }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 6.25C12 6.25 12 5 10.5 4.5L5 3C4 2.75 3 3.25 3 4.5V17C3 18 3.75 18.5 4.5 18.5L10.5 20C12 20.5 12 19.5 12 19.5" />
    <path d="M12 6.25C12 6.25 12 5 13.5 4.5L19 3C20 2.75 21 3.25 21 4.5V17C21 18 20.25 18.5 19.5 18.5L13.5 20C12 20.5 12 19.5 12 19.5" />
    <line x1="12" y1="6" x2="12" y2="20" />
  </svg>
);

const ShareIcon = ({ size = 20, color = colors.primary }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="18" cy="5" r="3" />
    <circle cx="6" cy="12" r="3" />
    <circle cx="18" cy="19" r="3" />
    <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
    <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
  </svg>
);

const HeartIcon = ({ size = 18, filled = false, color = colors.error }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? color : "none"} stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
  </svg>
);

const StarIcon = ({ size = 16, filled = false }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? "#D4A04A" : "none"} stroke="#D4A04A" strokeWidth="1.5">
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
  </svg>
);

const UserIcon = ({ size = 20, color = colors.textMuted }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
    <circle cx="12" cy="7" r="4" />
  </svg>
);

const SearchIcon = ({ size = 20, color = colors.textLight }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="11" cy="11" r="8" />
    <line x1="21" y1="21" x2="16.65" y2="16.65" />
  </svg>
);

const books = [
  { id: 1, title: "L'Étranger", author: "Albert Camus", rating: 4.5, sharedBy: "Marie L.", genre: "Classique", cover: "#A67B5B", likes: 24 },
  { id: 2, title: "Le Petit Prince", author: "Antoine de Saint-Exupéry", rating: 5, sharedBy: "Thomas R.", genre: "Conte", cover: "#7B9E6B", likes: 42 },
  { id: 3, title: "Fahrenheit 451", author: "Ray Bradbury", rating: 4, sharedBy: "Sophie M.", genre: "Science-fiction", cover: "#C4716C", likes: 18 },
  { id: 4, title: "Sapiens", author: "Yuval Noah Harari", rating: 4.5, sharedBy: "Lucas D.", genre: "Essai", cover: "#D4A04A", likes: 31 },
  { id: 5, title: "Persépolis", author: "Marjane Satrapi", rating: 4, sharedBy: "Amira K.", genre: "BD", cover: "#8B6F4E", likes: 15 },
  { id: 6, title: "Dune", author: "Frank Herbert", rating: 4.5, sharedBy: "Pierre V.", genre: "Science-fiction", cover: "#C4956A", likes: 37 },
];

const BookCard = ({ book }) => {
  const [liked, setLiked] = useState(false);
  return (
    <div style={{
      background: colors.surface,
      borderRadius: 16,
      overflow: "hidden",
      border: `1px solid ${colors.borderLight}`,
      transition: "all 0.3s ease",
      cursor: "pointer",
    }}
    onMouseEnter={e => { e.currentTarget.style.transform = "translateY(-4px)"; e.currentTarget.style.boxShadow = "0 12px 32px rgba(92,64,51,0.12)"; }}
    onMouseLeave={e => { e.currentTarget.style.transform = "translateY(0)"; e.currentTarget.style.boxShadow = "none"; }}
    >
      <div style={{
        height: 180,
        background: `linear-gradient(135deg, ${book.cover}, ${book.cover}dd)`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        position: "relative",
      }}>
        <div style={{
          width: 80,
          height: 120,
          background: "rgba(255,255,255,0.15)",
          borderRadius: 4,
          border: "1px solid rgba(255,255,255,0.25)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          backdropFilter: "blur(4px)",
        }}>
          <BookIcon size={32} color="rgba(255,255,255,0.8)" />
        </div>
        <span style={{
          position: "absolute",
          top: 12,
          right: 12,
          background: "rgba(255,255,255,0.9)",
          borderRadius: 20,
          padding: "4px 10px",
          fontSize: 11,
          fontWeight: 600,
          color: colors.primaryDark,
          fontFamily: "'Georgia', serif",
        }}>{book.genre}</span>
      </div>
      <div style={{ padding: "16px 18px 18px" }}>
        <h3 style={{
          margin: 0,
          fontSize: 17,
          fontWeight: 700,
          color: colors.text,
          fontFamily: "'Georgia', serif",
          lineHeight: 1.3,
        }}>{book.title}</h3>
        <p style={{
          margin: "4px 0 10px",
          fontSize: 13,
          color: colors.textMuted,
          fontFamily: "'Georgia', serif",
          fontStyle: "italic",
        }}>{book.author}</p>
        <div style={{ display: "flex", gap: 2, marginBottom: 12 }}>
          {[1,2,3,4,5].map(s => (
            <StarIcon key={s} size={14} filled={s <= Math.floor(book.rating)} />
          ))}
          <span style={{ fontSize: 12, color: colors.textLight, marginLeft: 6 }}>{book.rating}</span>
        </div>
        <div style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          paddingTop: 12,
          borderTop: `1px solid ${colors.borderLight}`,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{
              width: 26,
              height: 26,
              borderRadius: "50%",
              background: colors.surfaceWarm,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}>
              <UserIcon size={14} color={colors.secondary} />
            </div>
            <span style={{ fontSize: 12, color: colors.textMuted }}>{book.sharedBy}</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <button onClick={e => { e.stopPropagation(); setLiked(!liked); }}
              style={{
                background: "none", border: "none", cursor: "pointer",
                display: "flex", alignItems: "center", gap: 4, padding: 0,
              }}>
              <HeartIcon size={16} filled={liked} />
              <span style={{ fontSize: 12, color: colors.textMuted }}>{liked ? book.likes + 1 : book.likes}</span>
            </button>
            <ShareIcon size={16} color={colors.textLight} />
          </div>
        </div>
      </div>
    </div>
  );
};

const ColorSwatch = ({ color, name, hex }) => (
  <div style={{ textAlign: "center" }}>
    <div style={{
      width: 64, height: 64, borderRadius: 12,
      background: hex, border: `1px solid ${colors.borderLight}`,
      margin: "0 auto 8px",
      boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
    }} />
    <div style={{ fontSize: 11, fontWeight: 600, color: colors.text }}>{name}</div>
    <div style={{ fontSize: 10, color: colors.textLight, fontFamily: "monospace" }}>{hex}</div>
  </div>
);

export default function BiblioShareApp() {
  const [activeTab, setActiveTab] = useState("discover");
  const [searchFocused, setSearchFocused] = useState(false);

  return (
    <div style={{
      minHeight: "100vh",
      background: colors.background,
      fontFamily: "'Georgia', 'Palatino Linotype', serif",
    }}>
      {/* Header */}
      <header style={{
        background: "linear-gradient(180deg, #FFFFFF 0%, #FFF8F0 100%)",
        borderBottom: `1px solid ${colors.borderLight}`,
        padding: "0 24px",
        position: "sticky",
        top: 0,
        zIndex: 100,
      }}>
        <div style={{
          maxWidth: 1100,
          margin: "0 auto",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          height: 64,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: `linear-gradient(135deg, ${colors.primaryLight}, ${colors.primary})`,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <BookIcon size={20} color="#fff" />
            </div>
            <span style={{
              fontSize: 22, fontWeight: 700, color: colors.primaryDark,
              letterSpacing: 1,
            }}>BiblioShare</span>
          </div>
          <div style={{
            display: "flex", alignItems: "center",
            background: searchFocused ? colors.surface : colors.backgroundWarm,
            border: `1.5px solid ${searchFocused ? colors.accent : colors.borderLight}`,
            borderRadius: 12, padding: "8px 14px", gap: 8,
            transition: "all 0.2s ease", width: 280,
          }}>
            <SearchIcon size={18} />
            <input
              placeholder="Rechercher un livre..."
              onFocus={() => setSearchFocused(true)}
              onBlur={() => setSearchFocused(false)}
              style={{
                border: "none", background: "transparent", outline: "none",
                fontSize: 14, color: colors.text, fontFamily: "inherit", width: "100%",
              }}
            />
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <button style={{
              background: `linear-gradient(135deg, ${colors.primaryLight}, ${colors.primary})`,
              color: "#fff", border: "none", borderRadius: 10,
              padding: "9px 18px", fontSize: 13, fontWeight: 600,
              cursor: "pointer", fontFamily: "inherit",
              boxShadow: "0 2px 8px rgba(139,111,78,0.25)",
            }}>+ Partager un livre</button>
            <div style={{
              width: 36, height: 36, borderRadius: "50%",
              background: colors.surfaceWarm, border: `1.5px solid ${colors.border}`,
              display: "flex", alignItems: "center", justifyContent: "center",
              cursor: "pointer",
            }}>
              <UserIcon size={18} color={colors.secondary} />
            </div>
          </div>
        </div>
      </header>

      <div style={{ maxWidth: 1100, margin: "0 auto", padding: "0 24px" }}>
        {/* Hero */}
        <section style={{
          textAlign: "center",
          padding: "48px 0 36px",
        }}>
          <h1 style={{
            fontSize: 38,
            fontWeight: 700,
            color: colors.primaryDark,
            margin: "0 0 12px",
            lineHeight: 1.2,
            letterSpacing: -0.5,
          }}>Partagez vos lectures,<br />découvrez celles des autres</h1>
          <p style={{
            fontSize: 17,
            color: colors.textMuted,
            margin: 0,
            maxWidth: 500,
            marginLeft: "auto",
            marginRight: "auto",
            lineHeight: 1.6,
            fontStyle: "italic",
          }}>
            Une communauté chaleureuse de lecteurs passionnés qui partagent leurs coups de cœur littéraires.
          </p>
        </section>

        {/* Stats bar */}
        <div style={{
          display: "flex",
          justifyContent: "center",
          gap: 48,
          padding: "20px 0 36px",
        }}>
          {[
            { label: "Livres partagés", value: "2,847" },
            { label: "Lecteurs actifs", value: "1,203" },
            { label: "Échanges ce mois", value: "456" },
          ].map(s => (
            <div key={s.label} style={{ textAlign: "center" }}>
              <div style={{ fontSize: 28, fontWeight: 700, color: colors.primary }}>{s.value}</div>
              <div style={{ fontSize: 12, color: colors.textLight, marginTop: 2 }}>{s.label}</div>
            </div>
          ))}
        </div>

        {/* Tabs */}
        <div style={{
          display: "flex",
          gap: 4,
          marginBottom: 28,
          background: colors.surfaceWarm,
          borderRadius: 12,
          padding: 4,
          width: "fit-content",
        }}>
          {[
            { id: "discover", label: "Découvrir" },
            { id: "popular", label: "Populaires" },
            { id: "recent", label: "Récents" },
          ].map(t => (
            <button key={t.id} onClick={() => setActiveTab(t.id)} style={{
              background: activeTab === t.id ? colors.surface : "transparent",
              border: "none",
              borderRadius: 10,
              padding: "10px 20px",
              fontSize: 14,
              fontWeight: activeTab === t.id ? 600 : 400,
              color: activeTab === t.id ? colors.primaryDark : colors.textMuted,
              cursor: "pointer",
              fontFamily: "inherit",
              boxShadow: activeTab === t.id ? "0 1px 4px rgba(0,0,0,0.06)" : "none",
              transition: "all 0.2s ease",
            }}>{t.label}</button>
          ))}
        </div>

        {/* Book grid */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: 24,
          marginBottom: 48,
        }}>
          {books.map(book => <BookCard key={book.id} book={book} />)}
        </div>

        {/* Color Palette Section */}
        <section style={{
          background: colors.surface,
          borderRadius: 20,
          padding: "36px 40px",
          border: `1px solid ${colors.borderLight}`,
          marginBottom: 48,
        }}>
          <h2 style={{
            fontSize: 24, fontWeight: 700, color: colors.primaryDark,
            margin: "0 0 8px", textAlign: "center",
          }}>Palette de couleurs</h2>
          <p style={{
            fontSize: 14, color: colors.textMuted, textAlign: "center",
            margin: "0 0 28px", fontStyle: "italic",
          }}>Tons chauds et doux inspirés du papier ancien et du cuir</p>
          <div style={{
            display: "flex", justifyContent: "center", gap: 20, flexWrap: "wrap",
          }}>
            <ColorSwatch name="Primary" hex="#8B6F4E" />
            <ColorSwatch name="Primary Light" hex="#C4956A" />
            <ColorSwatch name="Primary Dark" hex="#5C4033" />
            <ColorSwatch name="Secondary" hex="#A67B5B" />
            <ColorSwatch name="Accent" hex="#D4A574" />
            <ColorSwatch name="Background" hex="#FFF8F0" />
            <ColorSwatch name="Surface Warm" hex="#F5E6D3" />
            <ColorSwatch name="Success" hex="#7B9E6B" />
            <ColorSwatch name="Error" hex="#C4716C" />
            <ColorSwatch name="Warning" hex="#D4A04A" />
          </div>
        </section>

        {/* Typography Section */}
        <section style={{
          background: colors.surface,
          borderRadius: 20,
          padding: "36px 40px",
          border: `1px solid ${colors.borderLight}`,
          marginBottom: 48,
        }}>
          <h2 style={{
            fontSize: 24, fontWeight: 700, color: colors.primaryDark,
            margin: "0 0 24px", textAlign: "center",
          }}>Typographie</h2>
          <div style={{ maxWidth: 600, margin: "0 auto" }}>
            {[
              { label: "H1 — Titre principal", size: 36, weight: 700 },
              { label: "H2 — Sous-titre", size: 24, weight: 700 },
              { label: "H3 — Titre de section", size: 18, weight: 600 },
              { label: "Body — Texte courant", size: 15, weight: 400 },
              { label: "Caption — Légende", size: 12, weight: 400 },
            ].map((t, i) => (
              <div key={i} style={{
                display: "flex", alignItems: "baseline", justifyContent: "space-between",
                padding: "14px 0",
                borderBottom: i < 4 ? `1px solid ${colors.borderLight}` : "none",
              }}>
                <span style={{
                  fontSize: t.size, fontWeight: t.weight,
                  color: colors.primaryDark, fontFamily: "'Georgia', serif",
                }}>{t.label}</span>
                <span style={{
                  fontSize: 11, color: colors.textLight, fontFamily: "monospace",
                }}>{t.size}px / {t.weight}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Buttons & Components */}
        <section style={{
          background: colors.surface,
          borderRadius: 20,
          padding: "36px 40px",
          border: `1px solid ${colors.borderLight}`,
          marginBottom: 48,
        }}>
          <h2 style={{
            fontSize: 24, fontWeight: 700, color: colors.primaryDark,
            margin: "0 0 24px", textAlign: "center",
          }}>Composants UI</h2>
          <div style={{ display: "flex", gap: 16, justifyContent: "center", flexWrap: "wrap", marginBottom: 24 }}>
            <button style={{
              background: `linear-gradient(135deg, ${colors.primaryLight}, ${colors.primary})`,
              color: "#fff", border: "none", borderRadius: 10,
              padding: "12px 24px", fontSize: 14, fontWeight: 600,
              cursor: "pointer", fontFamily: "inherit",
              boxShadow: "0 2px 8px rgba(139,111,78,0.25)",
            }}>Bouton primaire</button>
            <button style={{
              background: "transparent", color: colors.primary,
              border: `2px solid ${colors.primary}`, borderRadius: 10,
              padding: "10px 22px", fontSize: 14, fontWeight: 600,
              cursor: "pointer", fontFamily: "inherit",
            }}>Bouton secondaire</button>
            <button style={{
              background: colors.surfaceWarm, color: colors.primaryDark,
              border: `1px solid ${colors.border}`, borderRadius: 10,
              padding: "11px 22px", fontSize: 14, fontWeight: 400,
              cursor: "pointer", fontFamily: "inherit",
            }}>Bouton tertiaire</button>
          </div>
          <div style={{ display: "flex", gap: 12, justifyContent: "center", flexWrap: "wrap" }}>
            {["Classique", "Science-fiction", "Essai", "BD", "Conte"].map(g => (
              <span key={g} style={{
                background: colors.backgroundWarm, border: `1px solid ${colors.border}`,
                borderRadius: 20, padding: "6px 16px", fontSize: 13,
                color: colors.primaryDark, fontWeight: 500,
              }}>{g}</span>
            ))}
          </div>
        </section>

        {/* Footer */}
        <footer style={{
          textAlign: "center",
          padding: "32px 0 48px",
          borderTop: `1px solid ${colors.borderLight}`,
        }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, marginBottom: 8 }}>
            <BookIcon size={18} color={colors.secondary} />
            <span style={{ fontSize: 16, fontWeight: 600, color: colors.secondary }}>BiblioShare</span>
          </div>
          <p style={{ fontSize: 13, color: colors.textLight, margin: 0 }}>
            Partagez vos lectures, découvrez celles des autres © 2026
          </p>
        </footer>
      </div>
    </div>
  );
}
