INSERT INTO mf_tag(code, description) VALUES (E'T1', E'Quis saber se havia no estado/cidade serviços de acolhimento')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T2', E'Talvez pretende incluir uma criança e/ou adolescente no plano de fuga')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T3', E'Sim, pretende incluir uma criança e/ou adolescente no plano de fuga')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T4', E'Não pretende incluir uma criança e/ou adolescente no plano de fuga')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T5', E'Sim, possuí renda (trabalho ou benefício)')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T6', E'Depende financeiramente do agressor/tem seu dinheiro controlado por ele')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T7', E'Tem deficiência física ou intelectual')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'T8', E'Está grávida')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'SIM_LIMPA_MF', E'Caso responda sim, vai limpar as tarefas')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
INSERT INTO mf_tag(code, description) VALUES (E'NAO_LIMPA_MF', E'Caso responda nao, vai limpar as tarefas')
                   ON CONFLICT (code) DO UPDATE
                   SET description = EXCLUDED.description;
