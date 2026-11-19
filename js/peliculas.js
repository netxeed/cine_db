/* ==========================================================
   peliculas.js: datos de las películas y funciones para
   buscarlas, filtrarlas y dibujarlas (tarjetas y ficha).
   ========================================================== */

// Lista de géneros disponibles en el menú "Películas"
const GENEROS = ["Acción", "Comedia", "Terror", "Ciencia ficción", "Drama", "Animación", "Aventura", "Romance"];

// BASE DE DATOS FICTICIA: cada película es un objeto.
// estado "cartelera" = disponible ahora, "estreno" = próximamente.
// colores: se usan para el póster generado. imagen: si pones un archivo en
// assets/img/ (por ejemplo "eclipse.jpg") se mostrará en lugar del degradado.
const PELICULAS = [
  { id: 1, titulo: "Eclipse Carmesí", generos: ["Acción", "Aventura"], duracion: 128, clasificacion: "+13", estreno: "2026-10-30", estado: "cartelera", colores: ["#8a1630", "#1d0b2e"], imagen: null,
    sinopsis: "Cuando el sol se apaga durante tres minutos, una piloto de rescate debe cruzar un desierto helado para entregar una carga que podría devolver la luz al mundo." },
  { id: 2, titulo: "Risas en el Ascensor", generos: ["Comedia"], duracion: 98, clasificacion: "ATP", estreno: "2026-11-06", estado: "cartelera", colores: ["#d98e1f", "#4a1d5c"], imagen: null,
    sinopsis: "Cinco desconocidos quedan atrapados en un ascensor la noche de fin de año. Lo que empieza como un desastre termina siendo la mejor fiesta de sus vidas." },
  { id: 3, titulo: "La Casa del Silencio", generos: ["Terror"], duracion: 104, clasificacion: "+16", estreno: "2026-10-16", estado: "cartelera", colores: ["#1a1a2e", "#5b0f1d"], imagen: null,
    sinopsis: "Una familia se muda a una casa donde nadie logra hablar en voz alta. Pronto descubren que algo escucha cada susurro." },
  { id: 4, titulo: "Órbita Cero", generos: ["Ciencia ficción", "Drama"], duracion: 142, clasificacion: "+13", estreno: "2026-11-13", estado: "cartelera", colores: ["#0d2a5c", "#6a2fb0"], imagen: null,
    sinopsis: "La tripulación de una estación espacial pierde contacto con la Tierra y debe decidir si regresar a un planeta que quizás ya no los espera." },
  { id: 5, titulo: "Cartas a Elena", generos: ["Romance", "Drama"], duracion: 112, clasificacion: "+13", estreno: "2026-11-06", estado: "cartelera", colores: ["#a83a5a", "#2a1033"], imagen: null,
    sinopsis: "Un cartero jubilado encuentra cartas de amor que nunca llegaron a destino y decide recorrer el país para entregarlas, treinta años tarde." },
  { id: 6, titulo: "Pingüino Ninja", generos: ["Animación", "Aventura"], duracion: 91, clasificacion: "ATP", estreno: "2026-10-23", estado: "cartelera", colores: ["#1d8fb8", "#2b2a6e"], imagen: null,
    sinopsis: "Pipo es el pingüino más torpe de la Antártida, pero sueña con ser guardián del hielo. Un maestro inesperado le enseñará que el valor no depende de la altura." },
  { id: 7, titulo: "Furia en la Autopista", generos: ["Acción"], duracion: 119, clasificacion: "+16", estreno: "2026-11-13", estado: "cartelera", colores: ["#c2410c", "#1c1917"], imagen: null,
    sinopsis: "Una conductora de camiones descubre que su carga es buscada por una banda armada. Tiene 600 kilómetros de ruta para sobrevivir." },
  { id: 8, titulo: "El Último Faro", generos: ["Drama"], duracion: 126, clasificacion: "+13", estreno: "2026-10-09", estado: "cartelera", colores: ["#2f4858", "#0f1620"], imagen: null,
    sinopsis: "El último farero de la costa sur recibe la visita de su hija, a quien no ve hace veinte años, justo cuando el gobierno decide automatizar el faro." },
  { id: 9, titulo: "Mundo Mínimo", generos: ["Animación", "Comedia"], duracion: 95, clasificacion: "ATP", estreno: "2026-11-06", estado: "cartelera", colores: ["#3aa36b", "#233a8a"], imagen: null,
    sinopsis: "Dentro de un jardín, una hormiga inventora y un caracol perezoso se unen para salvar su vecindario de una regadera gigante." },
  { id: 10, titulo: "Marea Negra", generos: ["Terror", "Ciencia ficción"], duracion: 109, clasificacion: "+16", estreno: "2026-10-30", estado: "cartelera", colores: ["#06242e", "#3b0a4d"], imagen: null,
    sinopsis: "Una plataforma petrolera en alta mar extrae algo que no es petróleo. La tripulación tiene que escapar antes de que suba la marea." },
  // ----- Próximos estrenos -----
  { id: 11, titulo: "Corazón de Neón", generos: ["Romance", "Ciencia ficción"], duracion: 117, clasificacion: "+13", estreno: "2026-12-11", estado: "estreno", colores: ["#d6336c", "#2d1b69"], imagen: null,
    sinopsis: "En una ciudad futurista donde las emociones se compran, una vendedora de recuerdos se enamora de un cliente que no tiene ninguno." },
  { id: 12, titulo: "Los Guardianes del Valle", generos: ["Aventura", "Animación"], duracion: 101, clasificacion: "ATP", estreno: "2026-12-18", estado: "estreno", colores: ["#2f9e44", "#1b3a57"], imagen: null,
    sinopsis: "Tres hermanos descubren que el bosque detrás de su casa está protegido por criaturas antiguas, y que una sombra quiere despertarlas." },
  { id: 13, titulo: "Noche de Cobre", generos: ["Acción", "Drama"], duracion: 133, clasificacion: "+16", estreno: "2027-01-08", estado: "estreno", colores: ["#b45309", "#1f1530"], imagen: null,
    sinopsis: "Un exbombero regresa a su pueblo minero para enfrentar a quienes provocaron el derrumbe que cambió su vida." },
  { id: 14, titulo: "La Fiesta Equivocada", generos: ["Comedia"], duracion: 99, clasificacion: "+13", estreno: "2027-01-22", estado: "estreno", colores: ["#7c3aed", "#be185d"], imagen: null,
    sinopsis: "Lucía entra por error a una fiesta de disfraces de una familia millonaria y, para no ser descubierta, se hace pasar por la prima que nadie conoce." }
];

/* Quita tildes y mayúsculas para que "accion" encuentre "Acción". */
function normalizar(texto) {
  return texto.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().trim();
}

/* Convierte minutos en texto: 128 -> "2 h 8 min". */
function formatearDuracion(minutos) {
  return `${Math.floor(minutos / 60)} h ${minutos % 60} min`;
}

/* Convierte "2026-10-30" en "30 de octubre de 2026". */
function formatearFecha(iso) {
  return new Date(iso + "T00:00:00").toLocaleDateString("es-AR", { day: "numeric", month: "long", year: "numeric" });
}

/* Devuelve la película con ese id (o undefined si no existe). */
function buscarPorId(id) {
  return PELICULAS.find(p => p.id === id);
}

/* FILTRADO Y BÚSQUEDA: recorre la lista y se queda solo con las películas
   que cumplen las tres condiciones: estado, género (si se eligió uno) y
   texto (si se escribió algo, debe estar contenido en el título). */
function filtrarPeliculas(estado, genero, texto) {
  const t = normalizar(texto);
  return PELICULAS.filter(p =>
    p.estado === estado &&
    (!genero || p.generos.includes(genero)) &&
    (!t || normalizar(p.titulo).includes(t))
  );
}

/* Devuelve el HTML del póster: imagen real si existe, o degradado con el título. */
function crearPoster(p, base) {
  if (p.imagen) {
    return `<div class="poster"><img src="${base}assets/img/${p.imagen}" alt="Póster de ${p.titulo}"></div>`;
  }
  return `<div class="poster" role="img" aria-label="Póster de ${p.titulo}"
    style="background: linear-gradient(160deg, ${p.colores[0]}, ${p.colores[1]})"><span>${p.titulo}</span></div>`;
}

/* Devuelve el HTML de una tarjeta. "base" ayuda a armar el enlace a pages/pelicula.html
   (vacío desde index.html, "../" desde pages/). */
function crearTarjeta(p, base) {
  const enlace = `${base}pages/pelicula.html?id=${p.id}`;
  const estreno = p.estado === "estreno" ? `<p class="meta estreno-fecha">Estreno: ${formatearFecha(p.estreno)}</p>` : "";
  return `
    <article class="tarjeta">
      <a href="${enlace}" aria-label="Ver información de ${p.titulo}">${crearPoster(p, base)}</a>
      <div class="info">
        <h3>${p.titulo}</h3>
        <p class="meta">${p.generos.join(", ")}</p>
        <p class="meta">${formatearDuracion(p.duracion)}</p>
        ${estreno}
        <a class="ver-mas" href="${enlace}">Ver más información</a>
      </div>
    </article>`;
}

/* Devuelve el HTML completo de la pantalla de información de una película. */
function crearFicha(p, base) {
  return `
    <a class="volver" href="${base}index.html#cartelera">← Volver a la cartelera</a>
    <div class="ficha">
      ${crearPoster(p, base)}
      <div>
        <h1>${p.titulo}</h1>
        <div class="chips">${p.generos.map(g => `<span class="chip">${g}</span>`).join("")}</div>
        <dl class="datos">
          <div><dt>Duración</dt><dd>${formatearDuracion(p.duracion)}</dd></div>
          <div><dt>Clasificación</dt><dd>${p.clasificacion}</dd></div>
          <div><dt>Fecha de estreno</dt><dd>${formatearFecha(p.estreno)}</dd></div>
        </dl>
        <section class="sinopsis"><h2>Sinopsis</h2><p>${p.sinopsis}</p></section>
      </div>
    </div>`;
}
