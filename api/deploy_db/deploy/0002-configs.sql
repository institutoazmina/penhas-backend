BEGIN;

insert into emaildb_config (id, "from", template_resolver_class, template_resolver_config, email_transporter_class, email_transporter_config, delete_after)
values (
'1',
'"Penhas" <nao-responder@penhas.com.br>',    'Shypper::TemplateResolvers::HTTP',
'{"base_url":"https://localhost:9000/static/html-templates"}',
'Email::Sender::Transport::SMTP::TLS',
'{"password":"XXXX","username":"XXXX","port":"587","host":"smtp.gmail.com"}', '25 years'
);

insert into penhas_config(name, value)
values
('AVATAR_ANONIMO_URL','https://localhost:9000/avatar/anonimo.svg'),
('AVATAR_PADRAO_URL','https://localhost:9000/avatar/padrao.svg');


insert into penhas_config(name, value) values ('CPF_CACHE_HASH_SALT', md5(md5(random()::text)));

insert into penhas_config (name,value) values ('ANON_QUIZ_SECRET', uuid_generate_v4()::text);

INSERT INTO preferences (name, label, active, initial_value, sort, admin_only)
    VALUES ('POST_AS_PENHAS', 'Postar como PenhaS', TRUE, '0', 0, TRUE);
--

--insert into penhas_config (name,value,valid_from,valid_to)
--values ('AVATAR_ANONIMO_URL', 'https://localhost:9000/avatar/penhas_avatar.png', now(), 'infinity');

-- delete from penhas_config where "name"='AVATAR_PENHAS_URL';
insert into penhas_config (name,value,valid_from,valid_to)
values ('AVATAR_PENHAS_URL', 'https://localhost:9000/avatar/penhas_avatar.svg', now(), 'infinity');


COMMIT;
