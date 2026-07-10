DROP TABLE IF EXISTS listens;
DROP TABLE IF EXISTS tracks;
DROP TABLE IF EXISTS albums;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS users;

-- ПОЛЬЗОВАТЕЛИ
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    country VARCHAR(30) NOT NULL,
    subscription_type VARCHAR(20) NOT NULL,
    registration_date DATE NOT NULL
);

-- ИСПОЛНИТЕЛИ
CREATE TABLE artists (
    artist_id INT PRIMARY KEY AUTO_INCREMENT,
    artist_name VARCHAR(50) NOT NULL,
    country VARCHAR(30) NOT NULL
);

-- АЛЬБОМЫ
CREATE TABLE albums (
    album_id INT PRIMARY KEY AUTO_INCREMENT,
    artist_id INT NOT NULL,
    album_name VARCHAR(50) NOT NULL,
    tracks_amount INT NOT NULL,
    release_date DATE NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id)
);

-- ТРЕКИ
CREATE TABLE tracks (
    track_id INT PRIMARY KEY AUTO_INCREMENT,
    artist_id INT NOT NULL,
    album_id INT NOT NULL,
    track_name VARCHAR(100) NOT NULL,
    duration INT NOT NULL,
    genre VARCHAR(50) NOT NULL,
    release_date DATE NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id),
    FOREIGN KEY (album_id) REFERENCES albums(album_id)
);

-- ПРОСЛУШИВАНИЯ
CREATE TABLE listens (
    listen_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    artist_id INT NOT NULL,
    track_id INT NOT NULL,
    album_id INT NOT NULL,
    listen_date DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (artist_id) REFERENCES artists(artist_id),
    FOREIGN KEY (track_id) REFERENCES tracks(track_id),
    FOREIGN KEY (album_id) REFERENCES albums(album_id)
);
