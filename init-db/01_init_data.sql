-- =============================================================
-- SCRIPT D'INITIALISATION DES DONNÉES DE DÉMONSTRATION
-- =============================================================
-- Ce fichier est exécuté automatiquement par PostgreSQL
-- lors de la PREMIÈRE création du conteneur (si le volume pgdata
-- n'existe pas encore). Si le volume existe déjà, ce script
-- ne sera PAS ré-exécuté.
-- Pour forcer la ré-exécution : docker compose down -v
-- puis docker compose up -d
-- =============================================================

-- =============================================================
-- TABLE : ventes
-- Simule les ventes d'un institut de formation
-- =============================================================
CREATE TABLE IF NOT EXISTS ventes (
    id          SERIAL PRIMARY KEY,         -- Identifiant unique auto-incrémenté
    produit     VARCHAR(100) NOT NULL,      -- Nom de la formation vendue
    region      VARCHAR(50)  NOT NULL,      -- Région de vente
    montant     NUMERIC(10,2) NOT NULL,     -- Montant en euros
    quantite    INTEGER NOT NULL,           -- Nombre d'inscriptions
    date_vente  DATE NOT NULL               -- Date de la vente
);

-- =============================================================
-- INSERTION DES DONNÉES DE DÉMONSTRATION
-- 30 lignes couvrant 6 mois pour avoir des graphiques parlants
-- =============================================================
INSERT INTO ventes (produit, region, montant, quantite, date_vente) VALUES
-- Janvier 2024
('Formation Docker',        'Douala',   1500.00, 10, '2024-01-05'),
('Formation Python',        'Yaoundé',  1200.00,  8, '2024-01-10'),
('Formation Cloud AWS',     'Douala',   2500.00,  5, '2024-01-15'),
('Formation Linux',         'Bafoussam',  900.00,  6, '2024-01-20'),
('Formation DevOps',        'Yaoundé',  3000.00,  4, '2024-01-25'),

-- Février 2024
('Formation Docker',        'Yaoundé',  1500.00,  9, '2024-02-03'),
('Formation Python',        'Douala',   1200.00, 12, '2024-02-08'),
('Formation Cloud AWS',     'Bafoussam',2500.00,  3, '2024-02-14'),
('Formation Linux',         'Douala',    900.00,  7, '2024-02-19'),
('Formation DevOps',        'Yaoundé',  3000.00,  6, '2024-02-26'),

-- Mars 2024
('Formation Docker',        'Bafoussam',1500.00,  5, '2024-03-04'),
('Formation Python',        'Yaoundé',  1200.00, 15, '2024-03-11'),
('Formation Cloud AWS',     'Douala',   2500.00,  8, '2024-03-18'),
('Formation Linux',         'Yaoundé',   900.00,  4, '2024-03-22'),
('Formation DevOps',        'Douala',   3000.00,  7, '2024-03-29'),

-- Avril 2024
('Formation Docker',        'Douala',   1500.00, 11, '2024-04-02'),
('Formation Python',        'Bafoussam',1200.00,  6, '2024-04-09'),
('Formation Cloud AWS',     'Yaoundé',  2500.00,  9, '2024-04-16'),
('Formation Linux',         'Douala',    900.00,  8, '2024-04-23'),
('Formation DevOps',        'Bafoussam',3000.00,  3, '2024-04-30'),

-- Mai 2024
('Formation Docker',        'Yaoundé',  1500.00, 13, '2024-05-06'),
('Formation Python',        'Douala',   1200.00, 10, '2024-05-13'),
('Formation Cloud AWS',     'Douala',   2500.00,  6, '2024-05-20'),
('Formation Linux',         'Bafoussam', 900.00,  5, '2024-05-27'),
('Formation DevOps',        'Yaoundé',  3000.00,  8, '2024-05-31'),

-- Juin 2024
('Formation Docker',        'Douala',   1500.00, 14, '2024-06-03'),
('Formation Python',        'Yaoundé',  1200.00, 11, '2024-06-10'),
('Formation Cloud AWS',     'Bafoussam',2500.00,  7, '2024-06-17'),
('Formation Linux',         'Douala',    900.00,  9, '2024-06-24'),
('Formation DevOps',        'Douala',   3000.00, 10, '2024-06-30');

-- =============================================================
-- TABLE : etudiants
-- Simule les inscriptions d'étudiants pour enrichir le dashboard
-- =============================================================
CREATE TABLE IF NOT EXISTS etudiants (
    id              SERIAL PRIMARY KEY,
    nom             VARCHAR(100) NOT NULL,
    formation       VARCHAR(100) NOT NULL,
    date_inscription DATE NOT NULL,
    statut          VARCHAR(20) NOT NULL   -- 'actif', 'diplome', 'abandon'
);

INSERT INTO etudiants (nom, formation, date_inscription, statut) VALUES
('Etudiant A',  'Formation Docker',     '2024-01-05', 'diplome'),
('Etudiant B',  'Formation Python',     '2024-01-10', 'actif'),
('Etudiant C',  'Formation Cloud AWS',  '2024-01-15', 'actif'),
('Etudiant D',  'Formation Linux',      '2024-02-03', 'diplome'),
('Etudiant E',  'Formation DevOps',     '2024-02-08', 'actif'),
('Etudiant F',  'Formation Docker',     '2024-03-04', 'abandon'),
('Etudiant G',  'Formation Python',     '2024-03-11', 'actif'),
('Etudiant H',  'Formation Cloud AWS',  '2024-04-02', 'diplome'),
('Etudiant I',  'Formation Linux',      '2024-04-09', 'actif'),
('Etudiant J',  'Formation DevOps',     '2024-05-06', 'actif');
