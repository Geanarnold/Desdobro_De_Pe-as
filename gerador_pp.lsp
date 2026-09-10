;;; =============================================================================
;;; gerador_pp.lsp — Gerador de Layout Porta-Palete
;;; Compatível com AutoCAD 2013 ou superior
;;; Uso: carregue com APPLOAD e digite PORTAPALETE no prompt de comando
;;; =============================================================================

;;; Variável global para passar resultado do diálogo à função principal
(setq *pp-result* nil)

;; =============================================================================
;; SEÇÃO 1 — LAYERS
;; =============================================================================

(defun pp-criar-layers ()
  ;; Cria os layers necessários se ainda não existirem
  (pp-make-layer "PP-GALPAO"   4)   ; ciano
  (pp-make-layer "PP-MONTANTE" 1)   ; vermelho
  (pp-make-layer "PP-LONGARINA" 3)  ; verde
  (pp-make-layer "PP-CORREDOR" 8)   ; cinza
  (pp-make-layer "PP-PILAR"    6)   ; magenta
  (pp-make-layer "PP-COTAS"    5)   ; azul
  (pp-make-layer "PP-TEXTO"    2)   ; amarelo
)

(defun pp-make-layer (nome cor / )
  ;; Cria layer com a cor especificada (se não existir)
  (command "._-LAYER" "N" nome "C" (itoa cor) nome "")
)

;; =============================================================================
;; SEÇÃO 2 — PRIMITIVAS DE DESENHO
;; =============================================================================

(defun pp-set-layer (nome)
  (command "._-LAYER" "S" nome "")
)

(defun pp-rect (x1 y1 x2 y2 / )
  ;; Retângulo fechado usando PLINE
  (command "._PLINE"
           (list x1 y1)
           (list x2 y1)
           (list x2 y2)
           (list x1 y2)
           "C")
)

(defun pp-line (x1 y1 x2 y2 / )
  (command "._LINE" (list x1 y1) (list x2 y2) "")
)

(defun pp-circle (cx cy r / )
  (command "._CIRCLE" (list cx cy) r)
)

(defun pp-text (x y texto altura / )
  ;; Texto centralizado (justificado MC)
  (command "._TEXT" "J" "MC" (list x y) altura 0 texto)
)

(defun pp-dim-h (x1 x2 y_ref y_cota / )
  ;; Cota horizontal entre x1 e x2, linha de cota em y_cota
  (command "._DIMLINEAR"
           (list x1 y_ref)
           (list x2 y_ref)
           (list (* 0.5 (+ x1 x2)) y_cota))
)

(defun pp-dim-v (y1 y2 x_ref x_cota / )
  ;; Cota vertical entre y1 e y2, linha de cota em x_cota
  (command "._DIMLINEAR"
           (list x_ref y1)
           (list x_ref y2)
           (list x_cota (* 0.5 (+ y1 y2))))
)

;; =============================================================================
;; SEÇÃO 3 — CÁLCULO DE LAYOUT
;; =============================================================================

(defun pp-calc-mont-x (C F comprimento / n_mont larg_rack x_ini lista i)
  ;; Retorna lista de posições X dos montantes
  (setq n_mont  (fix (+ (/ (- comprimento (* 2.0 F)) C) 1))
        larg_rack (* (- n_mont 1) C)
        x_ini  (+ F (/ (- (- comprimento (* 2.0 F)) larg_rack) 2.0))
        lista  (list)
        i      0)
  (while (< i n_mont)
    (setq lista (append lista (list (+ x_ini (* i C))))
          i     (1+ i))
  )
  lista
)

(defun pp-calc-fileiras (A D E G largura tipo / lista y)
  ;; Retorna lista de dotted pairs (y0 . tipo_fil)
  ;; tipo_fil: "simples", "bb-frontal" ou "bb-traseira"
  (setq lista (list)
        y     E)

  (if (= tipo "simples")
    ;; Modo simples: fileiras individuais
    (progn
      (while (<= (+ y A) (- largura E))
        (setq lista (append lista (list (cons y "simples")))
              y     (+ y A G))
      )
    )
    ;; Modo duplo (back-to-back)
    (progn
      ;; Primeira fileira: sempre simples
      (if (<= (+ y A) (- largura E))
        (progn
          (setq lista (append lista (list (cons y "simples")))
                y     (+ y A G))
        )
      )
      ;; Pares back-to-back no meio
      (while (<= (+ y (* 3.0 A) D G) (- largura E))
        (setq lista (append lista
                      (list (cons y "bb-frontal"))
                      (list (cons (+ y A D) "bb-traseira")))
              y (+ y (* 2.0 A) D G))
      )
      ;; Última fileira: sempre simples
      (if (<= (+ y A) (- largura E))
        (setq lista (append lista (list (cons y "simples"))))
      )
    )
  )
  lista
)

(defun pp-calc-pilares (H I C A D G comp larg / lista px py modulo_y)
  ;; Retorna lista de dotted pairs (px . py)
  (setq lista    (list)
        modulo_y (+ A D G)
        px       H)
  (while (<= px comp)
    (setq py I)
    (while (<= py larg)
      (setq lista (append lista (list (cons px py)))
            py    (+ py modulo_y))
    )
    (setq px (+ px C))
  )
  lista
)

;; =============================================================================
;; SEÇÃO 4 — COMPONENTES EM PLANTA
;; =============================================================================

(defun pp-draw-montante (xm y0 A B col_prof / x_esq x_dir y_col_f_ini
                         y_col_f_fim y_col_t_ini y_col_t_fim
                         x_trav_ini x_trav_fim y_trav_t y_trav_f)
  ;; Desenha um montante em planta (vista de cima)
  ;; xm = centro X do montante
  ;; y0 = face frontal do montante (Y mínimo)
  ;; A  = profundidade total do montante
  ;; B  = largura frontal da coluna
  ;; col_prof = profundidade fixa da seção da coluna (70mm)
  (pp-set-layer "PP-MONTANTE")

  ;; Posições X das colunas
  (setq x_esq (- xm (/ B 2.0))
        x_dir (+ xm (/ B 2.0)))

  ;; Coluna frontal
  (setq y_col_f_ini y0
        y_col_f_fim (+ y0 col_prof))
  (pp-rect x_esq y_col_f_ini x_dir y_col_f_fim)

  ;; Coluna traseira
  (setq y_col_t_ini (+ y0 (- A col_prof))
        y_col_t_fim (+ y0 A))
  (pp-rect x_esq y_col_t_ini x_dir y_col_t_fim)

  ;; Travessas (entre as faces internas das colunas)
  (setq x_trav_ini (+ x_esq 20.0)
        x_trav_fim (- x_dir 20.0))

  ;; Travessa próxima à coluna frontal
  (setq y_trav_f y_col_f_fim)
  (pp-rect x_trav_ini y_trav_f x_trav_fim (+ y_trav_f 20.0))

  ;; Travessa próxima à coluna traseira
  (setq y_trav_t (- y_col_t_ini 20.0))
  (pp-rect x_trav_ini y_trav_t x_trav_fim y_col_t_ini)
)

(defun pp-draw-longarina-planta (x_esq x_dir y0 A alt_long / y_front y_tras)
  ;; Desenha longarinas frontais e traseiras entre dois montantes
  ;; y0 = face frontal da fileira, A = profundidade do montante
  (pp-set-layer "PP-LONGARINA")

  ;; Longarina frontal (na face frontal da fileira)
  (setq y_front y0)
  (pp-rect x_esq y_front x_dir (+ y_front alt_long))

  ;; Longarina traseira (na face traseira da fileira)
  (setq y_tras (- (+ y0 A) alt_long))
  (pp-rect x_esq y_tras x_dir (+ y_tras alt_long))

  ;; Linha central de posição de palete (entre as longarinas)
  (setq y_front y0)
  (pp-line x_esq (+ y_front (/ A 2.0)) x_dir (+ y_front (/ A 2.0)))
)

(defun pp-draw-pilar (cx cy / hs)
  ;; Desenha pilar estrutural 500×500mm com diagonais e círculo central
  (setq hs 250.0)
  (pp-set-layer "PP-PILAR")
  (pp-rect (- cx hs) (- cy hs) (+ cx hs) (+ cy hs))
  (pp-line (- cx hs) (- cy hs) (+ cx hs) (+ cy hs))
  (pp-line (+ cx hs) (- cy hs) (- cx hs) (+ cy hs))
  (pp-circle cx cy 50.0)
)

;; =============================================================================
;; SEÇÃO 5 — VISTA PLANTA BAIXA
;; =============================================================================

(defun pp-draw-planta (params fileiras pos_x pilares /
                       comp larg A B C D E F G
                       col_prof alt_long tipo
                       n_niveis h1 passo esp
                       i j x_mont y0 tp
                       x_esq_long x_dir_long
                       pos_total n_corredores
                       y_corr_ini y_corr_fim
                       txt_summary)

  ;; Extrai parâmetros
  (setq comp     (cdr (assoc "comprimento" params))
        larg     (cdr (assoc "largura"     params))
        A        (cdr (assoc "A"           params))
        B        (cdr (assoc "B"           params))
        C        (cdr (assoc "C"           params))
        D        (cdr (assoc "D"           params))
        E        (cdr (assoc "E"           params))
        F        (cdr (assoc "F"           params))
        G        (cdr (assoc "G"           params))
        col_prof 70.0
        alt_long (cdr (assoc "alt_long"    params))
        tipo     (cdr (assoc "tipo"        params))
        esp      (cdr (assoc "esp"         params))
  )

  ;; --- Contorno do galpão ---
  (pp-set-layer "PP-GALPAO")
  (pp-rect 0.0 0.0 comp larg)

  ;; --- Zonas de borda E (fundo e frente) e F (laterais) em PP-CORREDOR ---
  (pp-set-layer "PP-CORREDOR")
  ;; Borda fundo (y=0 até y=E)
  (pp-rect 0.0 0.0 comp E)
  ;; Borda frente
  (pp-rect 0.0 (- larg E) comp larg)
  ;; Borda lateral esquerda
  (pp-rect 0.0 0.0 F larg)
  ;; Borda lateral direita
  (pp-rect (- comp F) 0.0 comp larg)

  ;; --- Desenha pilares ---
  (foreach pilar pilares
    (pp-draw-pilar (car pilar) (cdr pilar))
  )

  ;; --- Processa cada fileira ---
  (setq pos_total  0
        n_corredores 0
        i          0)

  (while (< i (length fileiras))
    (setq y0 (car (nth i fileiras))
          tp (cdr (nth i fileiras)))

    ;; Desenha corredor antes da primeira fileira se for interior
    (if (and (> i 0)
             (not (and (= tp "bb-traseira")
                       (> i 0)
                       (= (cdr (nth (1- i) fileiras)) "bb-frontal"))))
      (progn
        (setq y_corr_ini (+ (car (nth (1- i) fileiras)) A)
              y_corr_fim y0)
        (if (> (- y_corr_fim y_corr_ini) 10.0)
          (progn
            (pp-set-layer "PP-CORREDOR")
            (pp-rect F y_corr_ini (- comp F) y_corr_fim)
            (pp-set-layer "PP-TEXTO")
            (pp-text (* 0.5 comp)
                     (* 0.5 (+ y_corr_ini y_corr_fim))
                     (strcat "CORREDOR G=" (rtos G 2 0) "mm")
                     (min 300.0 (* 0.4 (- y_corr_fim y_corr_ini))))
            (setq n_corredores (1+ n_corredores))
          )
        )
      )
    )

    ;; Desenha montantes e longarinas para esta fileira
    (setq j 0)
    (while (< j (length pos_x))
      (setq x_mont (nth j pos_x))
      (pp-draw-montante x_mont y0 A B col_prof)

      ;; Longarina entre montante j e j+1
      (if (< j (1- (length pos_x)))
        (progn
          (setq x_esq_long (+ x_mont (/ B 2.0))
                x_dir_long (- (nth (1+ j) pos_x) (/ B 2.0)))
          (pp-draw-longarina-planta x_esq_long x_dir_long y0 A alt_long)
          (setq pos_total (1+ pos_total))
        )
      )
      (setq j (1+ j))
    )
    (setq i (1+ i))
  )

  ;; --- Cotas externas ---
  (pp-set-layer "PP-COTAS")
  ;; Comprimento total
  (pp-dim-h 0.0 comp (- 0.0 E) (- 0.0 (* 2.5 (/ larg 40.0))))
  ;; Largura total
  (pp-dim-v 0.0 larg (+ comp E) (+ comp (* 2.5 (/ comp 40.0))))

  ;; --- Texto de resumo ---
  (pp-set-layer "PP-TEXTO")
  (setq txt_summary
    (strcat "PORTA-PALETE | Fileiras: " (itoa (length fileiras))
            " | Posicoes: " (itoa pos_total)
            " | Pilares: "  (itoa (length pilares))
            " | Tipo: "     tipo
            " | A=" (rtos A 2 0)
            " B=" (rtos B 2 0)
            " C=" (rtos C 2 0)
            " G=" (rtos G 2 0) "mm"))
  (pp-text (* 0.5 comp) (- 0.0 (* (/ larg 40.0) 5.5))
           txt_summary
           (min 400.0 (/ comp 50.0)))
)

;; =============================================================================
;; SEÇÃO 6 — VISTA ELEVAÇÃO FRONTAL
;; =============================================================================

(defun pp-draw-elevacao (params / comp larg A B C alt_long
                          n_niveis h1 passo esp
                          ox oy alt_total
                          x_mont_esq x_mont_dir
                          n h_nivel y_long_bot y_long_top
                          label_txt)
  ;; Vista de elevação, origem deslocada (comprimento + 4000, 0)
  (setq comp     (cdr (assoc "comprimento" params))
        larg     (cdr (assoc "largura"     params))
        A        (cdr (assoc "A"           params))
        B        (cdr (assoc "B"           params))
        C        (cdr (assoc "C"           params))
        alt_long (cdr (assoc "alt_long"    params))
        n_niveis (cdr (assoc "n_niveis"    params))
        h1       (cdr (assoc "h1"          params))
        passo    (cdr (assoc "passo"       params))
        esp      (cdr (assoc "esp"         params))

        ox       (+ comp 4000.0)
        oy       0.0
        alt_total (+ h1 (* (- n_niveis 1) passo) alt_long 500.0))

  ;; Montante esquerdo
  (pp-set-layer "PP-MONTANTE")
  (pp-rect ox oy (+ ox B) (+ oy alt_total))

  ;; Montante direito
  (setq x_mont_esq (+ ox C)
        x_mont_dir (+ ox C B))
  (pp-rect x_mont_esq oy x_mont_dir (+ oy alt_total))

  ;; Linha de piso
  (pp-set-layer "PP-GALPAO")
  (pp-line (- ox 500.0) oy (+ x_mont_dir 500.0) oy)

  ;; Longarinas por nível
  (setq n 0)
  (while (< n n_niveis)
    (setq h_nivel   (+ h1 (* n passo))
          y_long_bot (+ oy h_nivel)
          y_long_top (+ y_long_bot alt_long))

    ;; Longarina esquerda (face interna montante esq → 80mm)
    (pp-set-layer "PP-LONGARINA")
    (pp-rect (+ ox B) y_long_bot (+ ox B 80.0) y_long_top)

    ;; Longarina direita
    (pp-rect (- x_mont_esq 80.0) y_long_bot x_mont_esq y_long_top)

    ;; Linha de nível
    (pp-line (+ ox B 80.0) (+ y_long_bot (/ alt_long 2.0))
             (- x_mont_esq 80.0) (+ y_long_bot (/ alt_long 2.0)))

    ;; Label do nível
    (pp-set-layer "PP-TEXTO")
    (setq label_txt (strcat "N" (itoa (1+ n)) "=" (rtos h_nivel 2 0) "mm"))
    (pp-text (- ox 800.0) (+ y_long_bot (/ alt_long 2.0)) label_txt 200.0)

    (setq n (1+ n))
  )

  ;; Cotas
  (pp-set-layer "PP-COTAS")
  ;; Vão C
  (pp-dim-h ox (+ ox C B) (+ oy alt_total) (+ oy alt_total 800.0))
  ;; Altura total
  (pp-dim-v oy (+ oy alt_total) (+ x_mont_dir 300.0) (+ x_mont_dir 1200.0))

  ;; Título da vista
  (pp-set-layer "PP-TEXTO")
  (pp-text (+ ox (/ (+ C B) 2.0)) (- oy 600.0) "ELEVAÇÃO FRONTAL" 300.0)
)

;; =============================================================================
;; SEÇÃO 7 — VISTA CORTE TRANSVERSAL
;; =============================================================================

(defun pp-draw-corte (params / comp larg A B C D tipo
                       ox oy col_prof
                       x0 x1 x2 x3
                       y_col_f y_col_t)
  ;; Vista de corte, origem deslocada (0, largura + 4000)
  (setq comp    (cdr (assoc "comprimento" params))
        larg    (cdr (assoc "largura"     params))
        A       (cdr (assoc "A"           params))
        B       (cdr (assoc "B"           params))
        D       (cdr (assoc "D"           params))
        tipo    (cdr (assoc "tipo"        params))
        col_prof 70.0

        ox      0.0
        oy      (+ larg 4000.0))

  ;; --- Montante frontal (simples ou bb-frente) ---
  (pp-set-layer "PP-MONTANTE")

  (setq x0       ox
        x1       (+ ox B))

  ;; Coluna frontal
  (pp-rect x0 oy x1 (+ oy col_prof))
  ;; Coluna traseira
  (pp-rect x0 (+ oy (- A col_prof)) x1 (+ oy A))
  ;; Travessa frontal
  (pp-rect (+ x0 20.0) (+ oy col_prof) (- x1 20.0) (+ oy col_prof 20.0))
  ;; Travessa traseira
  (pp-rect (+ x0 20.0) (+ oy (- A col_prof) -20.0) (- x1 20.0) (+ oy (- A col_prof)))

  ;; --- Se back-to-back: segundo montante ---
  (if (= tipo "duplo")
    (progn
      (setq x2 (+ ox A D)
            x3 (+ ox A D B))
      ;; Coluna frontal traseira
      (pp-rect x2 oy x3 (+ oy col_prof))
      ;; Coluna traseira
      (pp-rect x2 (+ oy (- A col_prof)) x3 (+ oy A))
      ;; Travessas
      (pp-rect (+ x2 20.0) (+ oy col_prof) (- x3 20.0) (+ oy col_prof 20.0))
      (pp-rect (+ x2 20.0) (+ oy (- A col_prof) -20.0) (- x3 20.0) (+ oy (- A col_prof)))
    )
  )

  ;; Linha de piso
  (pp-set-layer "PP-GALPAO")
  (pp-line (- ox 300.0) oy
           (if (= tipo "duplo") (+ ox A D B 300.0) (+ ox A 300.0))
           oy)

  ;; Cotas
  (pp-set-layer "PP-COTAS")
  ;; Cota A
  (pp-dim-v oy (+ oy A) (+ ox (if (= tipo "duplo") (+ A D B) A) 300.0)
            (+ ox (if (= tipo "duplo") (+ A D B) A) 1200.0))
  ;; Cota B
  (pp-dim-h ox (+ ox B) (- oy 200.0) (- oy 800.0))
  ;; Cota D (se duplo)
  (if (= tipo "duplo")
    (pp-dim-h (+ ox A) (+ ox A D) (- oy 200.0) (- oy 1400.0))
  )

  ;; Título da vista
  (pp-set-layer "PP-TEXTO")
  (pp-text (+ ox (/ A 2.0)) (- oy 1200.0) "CORTE TRANSVERSAL" 300.0)
)

;; =============================================================================
;; SEÇÃO 8 — DIÁLOGO DCL
;; =============================================================================

(defun pp-validar (dcl_id / v_comp v_larg v_A v_C v_G ok msg)
  ;; Valida os campos do diálogo; retorna T se tudo ok, nil caso contrário
  (setq ok T)

  (setq v_comp (atof (get_tile "comprimento"))
        v_larg (atof (get_tile "largura"))
        v_A    (atof (get_tile "cota_a"))
        v_C    (atof (get_tile "cota_c"))
        v_G    (atof (get_tile "cota_g"))
        msg    "")

  (if (<= v_comp 0.0)
    (setq ok nil msg "Comprimento do galpão deve ser maior que zero.")
  )
  (if (and ok (<= v_larg 0.0))
    (setq ok nil msg "Largura do galpão deve ser maior que zero.")
  )
  (if (and ok (< v_A 200.0))
    (setq ok nil msg "Cota A (profundidade do montante) deve ser >= 200mm.")
  )
  (if (and ok (<= v_C 0.0))
    (setq ok nil msg "Cota C (comprimento da longarina) deve ser maior que zero.")
  )
  (if (and ok (< v_G 500.0))
    (setq ok nil msg "Cota G (largura do corredor) deve ser >= 500mm.")
  )

  (if (not ok)
    (set_tile "errtile" msg)
    (set_tile "errtile" "")
  )
  ok
)

(defun pp-coletar-valores (/ b_idx b_val n_idx tipo_val)
  ;; Lê os tiles do diálogo e salva em *pp-result*
  (setq b_idx  (atoi (get_tile "b_list"))
        b_val  (nth b_idx (list 80.0 101.0 122.0))
        n_idx  (1+ (atoi (get_tile "n_niv")))
        tipo_val (if (= (get_tile "tipo_d") "1") "duplo" "simples"))

  (setq *pp-result*
    (list
      (cons "comprimento" (atof (get_tile "comprimento")))
      (cons "largura"     (atof (get_tile "largura")))
      (cons "tipo"        tipo_val)
      (cons "A"           (atof (get_tile "cota_a")))
      (cons "B"           b_val)
      (cons "esp"         (atof (get_tile "esp")))
      (cons "C"           (atof (get_tile "cota_c")))
      (cons "alt_long"    (atof (get_tile "alt_long")))
      (cons "D"           (atof (get_tile "cota_d")))
      (cons "E"           (atof (get_tile "cota_e")))
      (cons "F"           (atof (get_tile "cota_f")))
      (cons "G"           (atof (get_tile "cota_g")))
      (cons "H"           (atof (get_tile "cota_h")))
      (cons "I"           (atof (get_tile "cota_i")))
      (cons "n_niveis"    n_idx)
      (cons "h1"          (atof (get_tile "h1")))
      (cons "passo"       (atof (get_tile "passo")))
    )
  )
)

(defun pp-show-dialog ( / dcl_file dcl_id resp)
  ;; Localiza o arquivo DCL na mesma pasta do LSP ou no suporte de pesquisa
  (setq dcl_file
    (findfile "gerador_pp.dcl")
  )
  (if (null dcl_file)
    (progn
      (alert "Arquivo gerador_pp.dcl não encontrado!\nColoque-o na mesma pasta que gerador_pp.lsp.")
      (setq *pp-result* nil)
      (exit)
    )
  )

  (setq dcl_id (load_dialog dcl_file))
  (if (< dcl_id 0)
    (progn
      (alert "Erro ao carregar o arquivo DCL.")
      (setq *pp-result* nil)
      (exit)
    )
  )

  (if (not (new_dialog "gerador_pp" dcl_id))
    (progn
      (alert "Erro ao criar o diálogo gerador_pp.")
      (unload_dialog dcl_id)
      (setq *pp-result* nil)
      (exit)
    )
  )

  ;; Define valores padrão nos tiles
  (set_tile "comprimento" "25000")
  (set_tile "largura"     "20000")
  (set_tile "tipo_d"      "1")
  (set_tile "tipo_s"      "0")
  (set_tile "cota_a"      "1000")
  (set_tile "b_list"      "0")
  (set_tile "esp"         "2.25")
  (set_tile "cota_c"      "2300")
  (set_tile "alt_long"    "93")
  (set_tile "cota_d"      "0")
  (set_tile "cota_e"      "500")
  (set_tile "cota_f"      "500")
  (set_tile "cota_g"      "3500")
  (set_tile "cota_h"      "2300")
  (set_tile "cota_i"      "2500")
  (set_tile "n_niv"       "3")
  (set_tile "h1"          "1000")
  (set_tile "passo"       "1000")
  (set_tile "errtile"     "")

  ;; Callback do botão OK
  (action_tile "accept"
    "(if (pp-validar dcl_id) (progn (pp-coletar-valores) (done_dialog 1)) )")

  ;; Callback do botão Cancel
  (action_tile "cancel"
    "(setq *pp-result* nil) (done_dialog 0)")

  (setq resp (start_dialog))
  (unload_dialog dcl_id)

  (if (= resp 1)
    *pp-result*
    nil
  )
)

;; =============================================================================
;; SEÇÃO 9 — COMANDO PRINCIPAL
;; =============================================================================

(defun c:PORTAPALETE ( / params fileiras pos_x pilares
                         comp larg A B C D E F G tipo
                         n_niveis h1 passo alt_long esp
                         old_cmdecho old_osmode
                         pos_total n_fil n_pil)

  ;; Abre o diálogo e coleta parâmetros
  (setq params (pp-show-dialog))
  (if (null params)
    (progn
      (princ "\nCancelado pelo usuário.")
      (exit)
    )
  )

  ;; Extrai valores para uso local
  (setq comp    (cdr (assoc "comprimento" params))
        larg    (cdr (assoc "largura"     params))
        tipo    (cdr (assoc "tipo"        params))
        A       (cdr (assoc "A"           params))
        B       (cdr (assoc "B"           params))
        C       (cdr (assoc "C"           params))
        D       (cdr (assoc "D"           params))
        E       (cdr (assoc "E"           params))
        F       (cdr (assoc "F"           params))
        G       (cdr (assoc "G"           params))
        alt_long (cdr (assoc "alt_long"   params))
        n_niveis (cdr (assoc "n_niveis"   params))
        h1       (cdr (assoc "h1"         params))
        passo    (cdr (assoc "passo"      params))
        esp      (cdr (assoc "esp"        params)))

  ;; Salva e desativa configurações do AutoCAD
  (setq old_cmdecho (getvar "CMDECHO")
        old_osmode  (getvar "OSMODE"))
  (setvar "CMDECHO" 0)
  (setvar "OSMODE"  0)

  ;; Cria layers
  (pp-criar-layers)

  ;; Calcula posições
  (setq pos_x   (pp-calc-mont-x C F comp)
        fileiras (pp-calc-fileiras A D E G larg tipo)
        pilares  (pp-calc-pilares (cdr (assoc "H" params))
                                  (cdr (assoc "I" params))
                                  C A D G comp larg))

  ;; Desenha as três vistas
  (pp-draw-planta   params fileiras pos_x pilares)
  (pp-draw-elevacao params)
  (pp-draw-corte    params)

  ;; Zoom extensão
  (command "._ZOOM" "E")

  ;; Restaura configurações
  (setvar "CMDECHO" old_cmdecho)
  (setvar "OSMODE"  old_osmode)

  ;; Resumo no prompt
  (setq n_fil (length fileiras)
        n_pil (length pilares)
        pos_total (* (max 0 (1- (length pos_x))) n_fil))

  (princ (strcat
    "\n*** PORTA-PALETE GERADO ***"
    "\n  Galpão: "       (rtos comp 2 0) " x " (rtos larg 2 0) " mm"
    "\n  Tipo: "         tipo
    "\n  Fileiras: "     (itoa n_fil)
    "\n  Montantes/fil: " (itoa (length pos_x))
    "\n  Posições de palete: " (itoa pos_total)
    "\n  Pilares: "      (itoa n_pil)
    "\n  Níveis: "       (itoa n_niveis)
    "\n  A=" (rtos A 2 0)
      " B=" (rtos B 2 0)
      " C=" (rtos C 2 0)
      " D=" (rtos D 2 0)
      " E=" (rtos E 2 0)
      " F=" (rtos F 2 0)
      " G=" (rtos G 2 0) " mm"
  ))
  (princ)
)

;; Atalho
(defun c:PP ()
  (c:PORTAPALETE)
)

;; =============================================================================
;; Mensagem de carregamento
;; =============================================================================
(princ "\n*** PORTAPALETE carregado — Digite: PORTAPALETE ***")
(princ)

;;; fim de gerador_pp.lsp
