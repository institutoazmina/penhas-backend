INSERT INTO tag(code, description) VALUES (E'T1', E'Quis saber havia no estado/cidade serviços de acolhimento')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO tag(code, description) VALUES (E'T2', E'Talvez pretende incluir uma criança e/ou adolescente no plano de fuga')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO tag(code, description) VALUES (E'SIM_LIMPA_MF', E'Caso responda sim, vai limpar as tarefas')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
