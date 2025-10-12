<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gerador de Códigos - PP/MP</title>
    <script src="https://unpkg.com/react@17/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@17/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css"></script>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body>
    <div id="root"></div>

    <script type="text/babel">
        function App() {
            // Seletor de família e produto
            const [family, setFamily] = React.useState(""); // PP, MP, GN, ES, CR
            const [product, setProduct] = React.useState(""); // COLUNA, LONGARINA, TRAVESSAS, SAPATAS, PLACAS NIVELADORAS

            // Campos específicos de COLUNA
            const [columnModel, setColumnModel] = React.useState(""); // COL 55, COL 80, COL 101, COL 122
            const [columnThickness, setColumnThickness] = React.useState(""); // lista por família
            const [columnHeight, setColumnHeight] = React.useState(""); // 500..8500 passo 50

            // Cor
            const [color, setColor] = React.useState(""); // AZ, LR, CZ, PT

            // Resultado
            const [code, setCode] = React.useState("");
            const [name, setName] = React.useState("");

            // Hist.
            const [history, setHistory] = React.useState([]);

            // Definições
            const families = [
                { code: "PP", label: "PP - PORTA PALETES" },
                { code: "MP", label: "MP - MINI PORTA PALETES" },
                { code: "GN", label: "GN - GONDOLAS" },
                { code: "ES", label: "ES - ESTANTE" },
                { code: "CR", label: "CR - CARRINHO" },
            ];

            const productsByFamily = (fam) => {
                const base = [
                    { code: "COLUNA", label: "COLUNA" },
                    { code: "LONGARINA", label: "LONGARINA" },
                    { code: "TRAVESSAS", label: "TRAVESSAS" },
                    { code: "SAPATAS", label: "SAPATAS" },
                    { code: "PLACAS", label: "PLACAS NIVELADORAS" },
                ];
                if (["PP", "MP"].includes(fam)) return base;
                return base;
            };

            const columnModelsByFamily = (fam) => {
                if (fam === "MP") return [{ code: "COL55", label: "COL 55" }];
                if (fam === "PP")
                    return [
                        { code: "COL80", label: "COL 80" },
                        { code: "COL101", label: "COL 101" },
                        { code: "COL122", label: "COL 122" },
                    ];
                return [];
            };

            const thicknessByFamily = (fam) => {
                if (fam === "MP")
                    return [
                        { code: "AA", label: "0,95mm", display: "0,95mm" },
                        { code: "AB", label: "1,20mm", display: "1,20mm" },
                        { code: "AC", label: "1,50mm", display: "1,50mm" },
                    ];
                if (fam === "PP")
                    return [
                        { code: "BA", label: "1,8mm", display: "1,8mm" },
                        { code: "BB", label: "2,0mm", display: "2,0mm" },
                        { code: "BC", label: "2,25mm", display: "2,25mm" },
                        { code: "BD", label: "2,65mm", display: "2,65mm" },
                    ];
                return [];
            };

            const heights = React.useMemo(() => {
                const arr = [];
                for (let h = 500; h <= 8500; h += 50) arr.push(h);
                return arr;
            }, []);

            const colors = [
                { code: "AZ", label: "Azul" },
                { code: "LR", label: "Laranja" },
                { code: "CZ", label: "Cinza" },
                { code: "PT", label: "Preto" },
            ];

            const resetDownstream = () => {
                setProduct("");
                setColumnModel("");
                setColumnThickness("");
                setColumnHeight("");
                setColor("");
                setCode("");
                setName("");
            };

            const resetProductSpecific = () => {
                setColumnModel("");
                setColumnThickness("");
                setColumnHeight("");
                setColor("");
                setCode("");
                setName("");
            };

            const canGenerate = () => {
                if (!family || !product) return false;
                if (product === "COLUNA") {
                    return !!(columnModel && columnThickness && columnHeight && color);
                }
                return !!color;
            };

            const generate = () => {
                if (!canGenerate()) {
                    alert("Preencha todos os campos obrigatórios.");
                    return;
                }

                let newCode = "";
                let newName = "";

                if (product === "COLUNA") {
                    newCode = `${family}-${product.slice(0,3)}-${columnModel}-${String(columnHeight).padStart(4, '0')}-${columnThickness}-${color}`;
                    const famLabel = families.find(f => f.code === family)?.label || family;
                    const modelLabel = columnModelsByFamily(family).find(m => m.code === columnModel)?.label || columnModel;
                    const thickObj = thicknessByFamily(family).find(t => t.code === columnThickness);
                    const thickLabel = thickObj?.display || columnThickness;
                    const colorLabel = colors.find(c => c.code === color)?.label || color;
                    newName = `${famLabel} • Coluna ${modelLabel} • Altura ${columnHeight}mm • Esp. ${thickLabel} • Cor ${colorLabel}`;
                } else {
                    const famLabel = families.find(f => f.code === family)?.label || family;
                    const prodLabel = productsByFamily(family).find(p => p.code === product)?.label || product;
                    const colorLabel = colors.find(c => c.code === color)?.label || color;
                    newCode = `${family}-${product.slice(0,3)}-XXXX-0000-XX-${color}`;
                    newName = `${famLabel} • ${prodLabel} • Cor ${colorLabel}`;
                }

                setCode(newCode);
                setName(newName);
                setHistory((h) => [{ code: newCode, name: newName, at: new Date().toLocaleString() }, ...h]);
            };

            const exportCSV = () => {
                if (history.length === 0) return alert("Sem itens no histórico.");
                let csv = "Código,Nome,Data/Hora\\n";
                history.forEach((r) => {
                    csv += `${r.code},\"${r.name}\",${r.at}\\n`;
                });
                const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
                const url = URL.createObjectURL(blob);
                const a = document.createElement("a");
                a.href = url;
                a.download = "codigos_pp.csv";
                a.click();
                URL.revokeObjectURL(url);
            };

            return (
                <div className="min-h-screen bg-gray-50 p-6">
                    <div className="max-w-5xl mx-auto bg-white rounded-xl shadow p-6">
                        <h1 className="text-2xl font-bold text-indigo-900">Gerador de Códigos - PP/MP</h1>
                        <p className="text-gray-600 mb-6">Selecione a família, produto e parâmetros para gerar o código e o nome da peça.</p>

                        {/* Família */}
                        <div className="grid md:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-sm font-semibold mb-1">Família do Produto</label>
                                <select
                                    value={family}
                                    onChange={(e) => {
                                        setFamily(e.target.value);
                                        resetDownstream();
                                    }}
                                    className="w-full border rounded-lg p-3"
                                >
                                    <option value="">Selecione</option>
                                    {families.map((f) => (
                                        <option key={f.code} value={f.code}>{f.label}</option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-semibold mb-1">Produto</label>
                                <select
                                    value={product}
                                    onChange={(e) => {
                                        setProduct(e.target.value);
                                        resetProductSpecific();
                                    }}
                                    disabled={!family}
                                    className="w-full border rounded-lg p-3 disabled:bg-gray-100"
                                >
                                    <option value="">Selecione</option>
                                    {family && productsByFamily(family).map((p) => (
                                        <option key={p.code} value={p.code}>{p.label}</option>
                                    ))}
                                </select>
                            </div>
                        </div>

                        {/* Bloco específico para COLUNA */}
                        {product === "COLUNA" && (
                            <div className="mt-6 grid md:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-semibold mb-1">Modelo de Coluna</label>
                                    <select
                                        value={columnModel}
                                        onChange={(e) => setColumnModel(e.target.value)}
                                        disabled={!family}
                                        className="w-full border rounded-lg p-3 disabled:bg-gray-100"
                                    >
                                        <option value="">Selecione</option>
                                        {columnModelsByFamily(family).map((m) => (
                                            <option key={m.code} value={m.code}>{m.label}</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-semibold mb-1">Espessura da Coluna</label>
                                    <select
                                        value={columnThickness}
                                        onChange={(e) => setColumnThickness(e.target.value)}
                                        disabled={!family}
                                        className="w-full border rounded-lg p-3 disabled:bg-gray-100"
                                    >
                                        <option value="">Selecione</option>
                                        {thicknessByFamily(family).map((t) => (
                                            <option key={t.code} value={t.code}>{t.label} (Código: {t.code})</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-semibold mb-1">Altura (500 a 8500mm)</label>
                                    <select
                                        value={columnHeight}
                                        onChange={(e) => setColumnHeight(e.target.value)}
                                        className="w-full border rounded-lg p-3"
                                    >
                                        <option value="">Selecione</option>
                                        {heights.map((h) => (
                                            <option key={h} value={h}>{h} mm</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-semibold mb-1">Cor</label>
                                    <select
                                        value={color}
                                        onChange={(e) => setColor(e.target.value)}
                                        className="w-full border rounded-lg p-3"
                                    >
                                        <option value="">Selecione</option>
                                        {colors.map((c) => (
                                            <option key={c.code} value={c.code}>{c.label} ({c.code})</option>
                                        ))}
                                    </select>
                                </div>
                            </div>
                        )}

                        {/* Cor para outros produtos (placeholder até regras novas) */}
                        {product && product !== "COLUNA" && (
                            <div className="mt-6">
                                <label className="block text-sm font-semibold mb-1">Cor</label>
                                <select
                                    value={color}
                                    onChange={(e) => setColor(e.target.value)}
                                    className="w-full border rounded-lg p-3"
                                >
                                    <option value="">Selecione</option>
                                    {colors.map((c) => (
                                        <option key={c.code} value={c.code}>{c.label} ({c.code})</option>
                                    ))}
                                </select>
                            </div>
                        )}

                        <button
                            onClick={generate}
                            disabled={!canGenerate()}
                            className={`mt-6 w-full p-3 rounded-lg text-white font-semibold ${canGenerate() ? 'bg-indigo-600 hover:bg-indigo-700' : 'bg-gray-300 cursor-not-allowed'}`}
                        >
                            Gerar Código e Nome
                        </button>

                        {(code || name) && (
                            <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
                                <div className="mb-2 text-sm text-green-800 font-semibold">Código</div>
                                <div className="font-mono text-lg text-green-900 break-all">{code}</div>
                                <div className="mt-3 mb-2 text-sm text-green-800 font-semibold">Nome da Peça</div>
                                <div className="text-gray-800">{name}</div>
                            </div>
                        )}

                        {history.length > 0 && (
                            <div className="mt-8">
                                <div className="flex items-center justify-between">
                                    <h2 className="text-lg font-bold text-indigo-900">Histórico</h2>
                                    <button onClick={exportCSV} className="px-3 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">Exportar CSV</button>
                                </div>
                                <div className="overflow-x-auto mt-3">
                                    <table className="w-full text-sm">
                                        <thead>
                                            <tr className="bg-gray-100">
                                                <th className="text-left p-2">#</th>
                                                <th className="text-left p-2">Código</th>
                                                <th className="text-left p-2">Nome</th>
                                                <th className="text-left p-2">Data/Hora</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {history.map((r, i) => (
                                                <tr key={i} className="border-b">
                                                    <td className="p-2">{i + 1}</td>
                                                    <td className="p-2 font-mono text-indigo-700">{r.code}</td>
                                                    <td className="p-2">{r.name}</td>
                                                    <td className="p-2 text-gray-600">{r.at}</td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            );
        }

        ReactDOM.render(<App />, document.getElementById('root'));
    </script>
</body>
</html>
