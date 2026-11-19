/* ==========================================================
   main.js: punto de entrada. Se ejecuta cuando la página
   termina de cargar y decide qué dibujar según la página.
   ========================================================== */

document.addEventListener("DOMContentLoaded", () => {
  const base = document.body.dataset.base;     // "" en index.html, "../" en pages/
  const pagina = document.body.dataset.pagina; // "inicio" o "pelicula"

  construirCabecera(base);       // navegacion.js: cabecera y barra de navegación
  iniciarMenus(base, pagina);    // navegacion.js: menús y buscador
  iniciarUsuarios();             // usuarios.js: botones y formularios

  if (pagina === "inicio") iniciarInicio(base);
  else iniciarFicha(base);
});

/* PÁGINA DE INICIO: lee los filtros de la dirección (si vienen de otra página)
   y dibuja las tarjetas. */
function iniciarInicio(base) {
  const params = new URLSearchParams(location.search);
  filtros.genero = GENEROS.includes(params.get("genero")) ? params.get("genero") : "";
  filtros.texto = params.get("buscar") || "";
  document.getElementById("campo-buscar").value = filtros.texto;
  pintarGeneros(); actualizarEtiquetas();

  alCambiarFiltros = () => pintarCartelera(base); // cada cambio de filtro redibuja
  pintarCartelera(base);
}

/* Dibuja "En cartelera" y "Próximos estrenos" aplicando los filtros activos. */
function pintarCartelera(base) {
  const enCartelera = filtrarPeliculas("cartelera", filtros.genero, filtros.texto);
  const proximos = filtrarPeliculas("estreno", filtros.genero, filtros.texto);
  const grid = document.getElementById("grid-cartelera");

  // Si no hay coincidencias se muestra un mensaje con un botón para quitar filtros
  grid.innerHTML = enCartelera.length
    ? enCartelera.map(p => crearTarjeta(p, base)).join("")
    : `<div class="vacio"><p>No encontramos películas en cartelera con esos filtros.</p>
       <button class="btn-prim" id="btn-limpiar">Ver toda la cartelera</button></div>`;
  const limpiar = document.getElementById("btn-limpiar");
  if (limpiar) limpiar.addEventListener("click", limpiarFiltros);

  document.getElementById("grid-estrenos").innerHTML = proximos.map(p => crearTarjeta(p, base)).join("");
  document.getElementById("estrenos").hidden = proximos.length === 0; // oculta la sección si queda vacía

  // Resumen de filtros activos junto al título
  const partes = [];
  if (filtros.genero) partes.push(`Género: ${filtros.genero}`);
  if (filtros.texto.trim()) partes.push(`Búsqueda: "${filtros.texto.trim()}"`);
  document.getElementById("estado-filtros").textContent = partes.join(". ");
}

/* PÁGINA DE FICHA: toma el id de la dirección (?id=3) y muestra esa película. */
function iniciarFicha(base) {
  const id = parseInt(new URLSearchParams(location.search).get("id"), 10);
  const pelicula = buscarPorId(id);
  const ficha = document.getElementById("ficha");
  if (!pelicula) {
    ficha.innerHTML = `<p>No encontramos esa película.</p><a class="volver" href="${base}index.html">← Volver a la cartelera</a>`;
    return;
  }
  document.title = `CineNova | ${pelicula.titulo}`;
  ficha.innerHTML = crearFicha(pelicula, base);
}
