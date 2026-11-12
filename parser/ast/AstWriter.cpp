#include "AstWriter.h"

#include <algorithm>
#include <ostream>

namespace {
    void HtmlText(std::ostream& out, std::string_view text) {
        for (char ch : text) {
            switch (ch) {
                case '&': out << "&amp;"; break;
                case '<': out << "&lt;"; break;
                case '>': out << "&gt;"; break;
                case '\r': out << "&#13;"; break;
                default: out << ch; break;
            }
        }
    }

    // Preserve byte offsets even for an input with invalid UTF-8.
    void Base64(std::ostream& out, std::string_view bytes) {
        constexpr char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::size_t offset = 0;
        while (offset < bytes.size()) {
            const unsigned first = static_cast<unsigned char>(bytes[offset++]);
            const bool hasSecond = offset < bytes.size();
            const unsigned second = hasSecond ? static_cast<unsigned char>(bytes[offset++]) : 0;
            const bool hasThird = offset < bytes.size();
            const unsigned third = hasThird ? static_cast<unsigned char>(bytes[offset++]) : 0;
            out << alphabet[first >> 2] << alphabet[((first & 3) << 4) | (second >> 4)]
                << (hasSecond ? alphabet[((second & 15) << 2) | (third >> 6)] : '=')
                << (hasThird ? alphabet[third & 63] : '=');
        }
    }

    void DotText(std::ostream& out, std::string_view text) {
        for (char ch : text) {
            switch (ch) {
                case '"': out << "\\\""; break;
                case '\\': out << "\\\\"; break;
                case '\r': out << "\\r"; break;
                case '\n': out << "\\n"; break;
                case '\t': out << "\\t"; break;
                default: out << ch; break;
            }
        }
    }

    void Location(std::ostream& out, SourceRange range) {
        out << range.first_line << ':' << range.first_column
            << " – " << range.last_line << ':' << range.last_column;
    }

    void HtmlLabel(std::ostream& out, const AstNode& node) {
        out << "<span class=\"id\">#" << node.id << "</span> <strong>" << AstKindName(node.kind)
            << "</strong>";
        if (!node.text.empty()) {
            out << " <code class=\"value\">";
            HtmlText(out, node.text);
            out << "</code>";
        }
        out << " <small>";
        Location(out, node.range);
        out << "</small>";
        if (node.runeValue) out << " <small>код " << *node.runeValue << "</small>";
    }

    void HtmlRow(std::ostream& out, const AstNode& node, std::size_t depth) {
        const bool leaf = node.children.empty();
        if (leaf) out << "<button type=\"button\" class=\"leaf row\"";
        else out << "<details" << (depth < 3 ? " open" : "") << "><summary class=\"row\"";
        out << " id=\"n" << node.id << "\" data-begin=\"" << node.range.begin
            << "\" data-end=\"" << node.range.end << "\">";
        HtmlLabel(out, node);
        out << (leaf ? "</button>\n" : "</summary><div class=\"children\">\n");
    }

    void HtmlList(std::ostream& out, const AstNode& root) {
        struct Frame {
            const AstNode* node;
            std::size_t nextChild;
        };
        HtmlRow(out, root, 0);
        std::vector<Frame> stack;
        if (!root.children.empty()) stack.push_back({&root, 0});
        while (!stack.empty()) {
            Frame& frame = stack.back();
            if (frame.nextChild == frame.node->children.size()) {
                out << "</div></details>\n";
                stack.pop_back();
                continue;
            }
            const AstNode* child = frame.node->children[frame.nextChild++];
            HtmlRow(out, *child, stack.size());
            if (!child->children.empty()) stack.push_back({child, 0});
        }
    }

    constexpr std::size_t graphPadding = 24;
    constexpr std::size_t nodeWidth = 210;
    constexpr std::size_t nodeHeight = 54;
    constexpr std::size_t columnStep = nodeWidth + 24;
    constexpr std::size_t rowStep = nodeHeight + 44;

    struct GraphNode {
        const AstNode* node;
        std::size_t x;
        std::size_t y;
    };

    // Each leaf takes a column. Every subtree occupies one contiguous span.
    std::vector<GraphNode> PlaceNodes(const AstNode& root) {
        std::vector<GraphNode> nodes;
        std::vector<GraphNode> pending{{&root, 0, graphPadding}};
        std::size_t leafX = graphPadding + nodeWidth / 2;
        while (!pending.empty()) {
            GraphNode position = pending.back();
            pending.pop_back();
            const auto& children = position.node->children;
            if (children.empty()) {
                position.x = leafX;
                leafX += columnStep;
            }
            nodes.push_back(position);
            for (auto child = children.rbegin(); child != children.rend(); ++child) {
                pending.push_back({*child, 0, position.y + rowStep});
            }
        }

        for (auto position = nodes.rbegin(); position != nodes.rend(); ++position) {
            const auto& children = position->node->children;
            if (children.empty()) continue;
            const auto first = nodes[children.front()->id - 1].x;
            const auto last = nodes[children.back()->id - 1].x;
            position->x = first + (last - first) / 2;
        }
        return nodes;
    }

    std::string GraphLabel(std::string_view text) {
        std::string label;
        std::size_t count = 0;
        for (unsigned char ch : text) {
            if ((ch & 0xc0) != 0x80 && ++count > 22) {
                label += "…";
                break;
            }
            label += ch < 0x20 ? ' ' : static_cast<char>(ch);
        }
        return label;
    }

    void HtmlGraph(std::ostream& out, const AstNode& root) {
        const auto nodes = PlaceNodes(root);
        std::size_t width = 0;
        std::size_t height = 0;
        for (const auto& position : nodes) {
            width = std::max(width, position.x + nodeWidth / 2 + graphPadding);
            height = std::max(height, position.y + nodeHeight + graphPadding);
        }
        out << "<svg id=\"graph\" xmlns=\"http://www.w3.org/2000/svg\" role=\"group\" aria-label=\"Дерево AST\""
            << " width=\"" << width << "\" height=\"" << height << "\" viewBox=\"0 0 " << width << ' ' << height
            << "\">\n<g class=\"edges\" aria-hidden=\"true\">\n";
        for (const auto& position : nodes) {
            for (const AstNode* child : position.node->children) {
                const auto& end = nodes[child->id - 1];
                const auto bottom = position.y + nodeHeight;
                const auto middle = bottom + (end.y - bottom) / 2;
                out << "<path d=\"M" << position.x << ' ' << bottom << " C" << position.x << ' ' << middle
                    << ' ' << end.x << ' ' << middle << ' ' << end.x << ' ' << end.y << "\"/>\n";
            }
        }
        out << "</g>\n";
        for (const auto& position : nodes) {
            const auto& node = *position.node;
            out << "<g class=\"graph-node" << (node.children.empty() ? " terminal" : "")
                << "\" data-node=\"n" << node.id << "\" data-x=\"" << position.x << "\" data-y=\"" << position.y
                << "\" tabindex=\"0\" role=\"button\" transform=\"translate(" << position.x - nodeWidth / 2
                << ' ' << position.y << ")\"><title>";
            out << '#' << node.id << ' ' << AstKindName(node.kind);
            if (!node.text.empty()) {
                out << " · ";
                HtmlText(out, node.text);
            }
            out << "</title><rect width=\"" << nodeWidth << "\" height=\"" << nodeHeight << "\" rx=\"8\"/>"
                << "<text x=\"10\" y=\"21\"><tspan class=\"node-id\">#" << node.id << "</tspan> "
                << AstKindName(node.kind) << "</text><text class=\"node-detail\" x=\"10\" y=\"41\">";
            if (node.text.empty()) Location(out, node.range);
            else HtmlText(out, GraphLabel(node.text));
            out << "</text></g>\n";
        }
        out << "</svg>\n";
    }
}

void AstWriter::Html(std::ostream& out, const AstNode* root, std::string_view filename, std::string_view source,
                     std::string_view error, SourceRange errorRange) {
    out << R"HTML(<!doctype html>
<html lang="ru">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Дерево AST</title>
<style>
:root {
  color-scheme: light dark;
  --line: light-dark(#c7d3df,#374557);
  --accent: light-dark(#17529e,#9abcff);
  --panel: light-dark(#f3f7fb,#161e2a);
  --selected: light-dark(#e1edff,#263955);
  --error: light-dark(#9e3026,#ffb0a8);
}
* { box-sizing: border-box; }
body { font: 15px Inter,system-ui,sans-serif; margin: 0; background: Canvas; color: CanvasText; }
header, main { padding: 1rem clamp(1rem,3vw,2.5rem); }
header { border-bottom: 1px solid var(--line); }
h1 { margin: 0 0 .45rem; font-size: 1.65rem; }
h2 { font-size: 1.05rem; margin: 0 0 .65rem; }
.file { overflow-wrap: anywhere; }
nav { display: flex; flex-wrap: wrap; gap: .45rem; align-items: center; margin-bottom: .65rem; }
nav button { cursor: pointer; border: 1px solid var(--line); border-radius: .35rem; background: Canvas; color: CanvasText; padding: .35rem .65rem; }
nav button[aria-pressed="true"] { background: var(--selected); border-color: var(--accent); }
#views { display: grid; grid-template-columns: minmax(0,1fr) minmax(15rem,26%); gap: 1.2rem; align-items: start; }
#viewport { height: clamp(20rem,62vh,40rem); overflow: auto; border: 1px solid var(--line); border-radius: .55rem; background: var(--panel); cursor: grab; }
#viewport.dragging { cursor: grabbing; user-select: none; }
#graph { display: block; }
.edges { fill: none; stroke: light-dark(#8194aa,#74869f); stroke-width: 1.5; }
.graph-node { cursor: pointer; }
.dragging .graph-node { cursor: grabbing; }
.graph-node rect { fill: Canvas; stroke: var(--accent); stroke-width: 1.25; }
.graph-node.terminal rect { stroke: var(--line); }
.graph-node:hover rect, .graph-node:focus rect, .graph-node[aria-current="true"] rect { fill: var(--selected); stroke: var(--accent); stroke-width: 2.5; }
.graph-node.error-node rect { stroke: var(--error); stroke-width: 2.5; }
.graph-node text { fill: CanvasText; font: 600 13px Inter,system-ui,sans-serif; pointer-events: none; }
.graph-node .node-id, .graph-node .node-detail { fill: var(--accent); font: 12px ui-monospace,monospace; }
#tree { overflow-x: auto; padding: .25rem; }
.children { border-left: 1px solid var(--line); margin-left: .55rem; padding-left: .85rem; }
.row { text-align: left; cursor: pointer; padding: .3rem .4rem; border-radius: .35rem; overflow-wrap: anywhere; }
.row:hover, .row[aria-current="true"] { background: var(--selected); }
.leaf { display: block; font: inherit; color: inherit; background: none; border: 0; }
.id, small { color: GrayText; font-size: .78rem; }
.value { color: var(--accent); white-space: pre-wrap; }
aside { border: 1px solid var(--line); border-radius: .55rem; padding: 1rem; min-width: 0; }
pre { max-height: 65vh; overflow: auto; white-space: pre-wrap; overflow-wrap: anywhere; }
.problem { border-left: 3px solid var(--error); padding: .15rem .8rem; margin-bottom: 1rem; }
.problem pre { margin: .35rem 0; color: var(--error); }
mark { background: light-dark(#ffd7d2,#74413d); color: CanvasText; font-weight: bold; }
@media (max-width: 800px) { #views { grid-template-columns: minmax(0,1fr); } }
</style>
<header><h1>Дерево AST</h1><div class="file">)HTML";
    HtmlText(out, filename);
    out << "</div></header>\n<main>\n";

    if (!error.empty()) {
        out << "<section class=\"problem\" id=\"diagnostic\" data-begin=\"" << errorRange.begin
            << "\" data-end=\"" << errorRange.end << "\"><h2>"
            << (root ? "Дерево отклонено проверкой AST" : "Разбор остановился до построения AST")
            << "</h2><pre>" << errorRange.first_line << ':' << errorRange.first_column << ' ';
        HtmlText(out, error);
        out << "</pre></section>\n";
    }

    if (root) {
        out << R"HTML(<nav aria-label="Режим просмотра">
<button type="button" id="show-graph" aria-pressed="true">Граф</button>
<button type="button" id="show-list" aria-pressed="false">Список узлов</button>
</nav>
<div id="views">
<section aria-label="Узлы дерева">
<div id="graph-view">
<nav aria-label="Масштаб графа">
<button type="button" id="zoom-out" aria-label="Уменьшить">−</button>
<button type="button" id="zoom-in" aria-label="Увеличить">+</button>
<output id="zoom-value" aria-label="Текущий масштаб">100%</output>
<button type="button" id="zoom-fit">Уместить дерево</button>
</nav>
<div id="viewport" tabindex="0" aria-label="Панорама дерева. Перетащите для прокрутки">
)HTML";
        HtmlGraph(out, *root);
        out << R"HTML(</div></div>
<div id="list-view" hidden>
<nav aria-label="Управление списком">
<button type="button" id="expand">Развернуть всё</button>
<button type="button" id="collapse">Свернуть до корня</button>
</nav>
<div id="tree">
)HTML";
        HtmlList(out, *root);
        out << R"HTML(</div></div></section>
<aside><h2>Исходный код узла</h2><div id="selection"></div><pre id="excerpt"></pre></aside>
</div>
)HTML";
    } else {
        out << "<h2>Исходный код</h2><pre id=\"error-source\"></pre>\n";
    }
    out << "</main>\n<template id=\"source\">";
    Base64(out, source);
    out << R"HTML(</template>
<script>
const byId = id => document.getElementById(id);
const bytes = Uint8Array.from(atob(byId("source").content.textContent), ch => ch.charCodeAt(0));
const decoder = new TextDecoder("utf-8", { ignoreBOM: true });
const fragment = (begin, end) => decoder.decode(bytes.subarray(begin, end)).replaceAll("\u0000", "␀");
const diagnostic = byId("diagnostic");

function showErrorSource() {
  const begin = Number(diagnostic.dataset.begin);
  const end = Number(diagnostic.dataset.end);
  const mark = document.createElement("mark");
  mark.textContent = fragment(begin, end) || "▮";
  byId("error-source").append(fragment(0, begin), mark, fragment(end));
}

function setupTree() {
  const tree = byId("tree");
  const graph = byId("graph");
  const viewport = byId("viewport");
  const rows = [...tree.querySelectorAll(".row")];
  const rowById = new Map(rows.map(row => [row.id, row]));
  const nodes = new Map([...graph.querySelectorAll(".graph-node")].map(node => [node.dataset.node, node]));
  const naturalWidth = Number(graph.getAttribute("width"));
  const naturalHeight = Number(graph.getAttribute("height"));
  let selected;
  let scale = 1;

  function select(row) {
    if (selected) {
      selected.removeAttribute("aria-current");
      nodes.get(selected.id).removeAttribute("aria-current");
    }
    selected = row;
    row.setAttribute("aria-current", "true");
    nodes.get(row.id).setAttribute("aria-current", "true");
    byId("selection").textContent = row.textContent;
    byId("excerpt").textContent = fragment(Number(row.dataset.begin), Number(row.dataset.end));
  }

  function zoom(next, x = viewport.clientWidth / 2, y = viewport.clientHeight / 2) {
    const old = scale;
    scale = Math.min(2.5, Math.max(0.001, next));
    graph.setAttribute("width", naturalWidth * scale);
    graph.setAttribute("height", naturalHeight * scale);
    viewport.scrollLeft = (viewport.scrollLeft + x) * scale / old - x;
    viewport.scrollTop = (viewport.scrollTop + y) * scale / old - y;
    byId("zoom-value").textContent = (scale < 0.01 ? (scale * 100).toFixed(1) : Math.round(scale * 100)) + "%";
  }

  function setView(graphVisible) {
    byId("graph-view").hidden = !graphVisible;
    byId("list-view").hidden = graphVisible;
    byId("show-graph").setAttribute("aria-pressed", String(graphVisible));
    byId("show-list").setAttribute("aria-pressed", String(!graphVisible));
    if (!graphVisible) {
      for (let parent = selected.parentElement; parent && parent !== tree; parent = parent.parentElement) {
        if (parent.tagName === "DETAILS") parent.open = true;
      }
    }
  }

  byId("show-graph").addEventListener("click", () => setView(true));
  byId("show-list").addEventListener("click", () => setView(false));
  byId("zoom-in").addEventListener("click", () => zoom(scale * 1.25));
  byId("zoom-out").addEventListener("click", () => zoom(scale / 1.25));
  byId("zoom-fit").addEventListener("click", () => {
    zoom(Math.min(1, viewport.clientWidth / naturalWidth, viewport.clientHeight / naturalHeight), 0, 0);
    viewport.scrollLeft = viewport.scrollTop = 0;
  });

  tree.addEventListener("click", event => {
    const row = event.target.closest(".row");
    if (row) select(row);
  });
  graph.addEventListener("click", event => {
    const node = event.target.closest(".graph-node");
    if (node) select(rowById.get(node.dataset.node));
  });
  graph.addEventListener("keydown", event => {
    const node = event.target.closest(".graph-node");
    if (!node || (event.key !== "Enter" && event.key !== " ")) return;
    event.preventDefault();
    select(rowById.get(node.dataset.node));
  });

  byId("expand").addEventListener("click", () => {
    for (const branch of tree.querySelectorAll("details")) branch.open = true;
  });
  byId("collapse").addEventListener("click", () => {
    const branches = tree.querySelectorAll("details");
    for (const branch of branches) branch.open = branch === branches[0];
    select(rows[0]);
  });

  let drag;
  viewport.addEventListener("pointerdown", event => {
    if (event.button !== 0 || event.pointerType === "touch") return;
    drag = { id: event.pointerId, x: event.clientX, y: event.clientY,
             left: viewport.scrollLeft, top: viewport.scrollTop };
  });
  viewport.addEventListener("pointermove", event => {
    if (!drag || event.pointerId !== drag.id) return;
    const dx = event.clientX - drag.x;
    const dy = event.clientY - drag.y;
    if (!viewport.hasPointerCapture(drag.id)) {
      if (Math.hypot(dx, dy) < 5 || (event.buttons & 1) === 0) return;
      viewport.setPointerCapture(drag.id);
      viewport.classList.add("dragging");
    }
    viewport.scrollLeft = drag.left - dx;
    viewport.scrollTop = drag.top - dy;
  });
  for (const name of ["pointerup", "pointercancel", "lostpointercapture"]) {
    viewport.addEventListener(name, () => {
      drag = undefined;
      viewport.classList.remove("dragging");
    });
  }

  let first = rows[0];
  if (diagnostic) {
    const begin = Number(diagnostic.dataset.begin);
    const end = Number(diagnostic.dataset.end);
    let span = Infinity;
    for (const row of rows) {
      const start = Number(row.dataset.begin);
      const finish = Number(row.dataset.end);
      if (start <= begin && finish >= end && finish - start <= span) {
        first = row;
        span = finish - start;
      }
    }
    nodes.get(first.id).classList.add("error-node");
  }
  select(first);
  const firstNode = nodes.get(first.id);
  viewport.scrollLeft = Number(firstNode.dataset.x) - viewport.clientWidth / 2;
  if (diagnostic) viewport.scrollTop = Number(firstNode.dataset.y) - viewport.clientHeight / 2;
}

if (byId("graph")) setupTree();
else showErrorSource();
</script>
</html>
)HTML";
}

void AstWriter::Dot(std::ostream& out, const AstNode& root) {
    out << "digraph AST {\n  node [shape=box];\n";
    std::vector<const AstNode*> pending{&root};
    while (!pending.empty()) {
        const AstNode* node = pending.back();
        pending.pop_back();
        out << "  n" << node->id << " [label=\"#" << node->id << ' ' << AstKindName(node->kind);
        if (!node->text.empty()) {
            out << "\\n";
            DotText(out, node->text);
        }
        out << "\\n";
        Location(out, node->range);
        out << "\"];\n";
        for (const AstNode* child : node->children) out << "  n" << node->id << " -> n" << child->id << ";\n";
        pending.insert(pending.end(), node->children.rbegin(), node->children.rend());
    }
    out << "}\n";
}
