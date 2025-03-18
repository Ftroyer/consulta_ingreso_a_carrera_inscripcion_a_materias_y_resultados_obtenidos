
set search_path = "negocio";
WITH query_insc_prop AS (
    select sga_alumnos.alumno,
           mdp_personas.persona,
           mdp_personas.usuario as "dni",
           mdp_personas_contactos.email,
           sga_alumnos.calidad,
           sga_alumnos.regular as "alumno_regular",
           sga_alumnos.cnt_readmisiones as "alumno_cant_readmisiones",
           sga_ubicaciones.nombre as "ubicacion",
           replace(sga_situacion_aspirante.nombre, 'Aspirante a Propuesta', 'Aspirante a Propuesta o Pendiente') as "estado_insc_propuesta",
           sga_propuestas_tipos.descripcion as "nivel_propuesta_segun_periodo_insc_propuesta",
           case
               when sga_propuestas_tipos.descripcion not like 'Terciario'
                   then '-'
               when sga_propuestas.nombre ilike '%ciclo%'
                   then 'Ciclo Pedagógico'
               when sga_propuestas.nombre ilike '%volante%'
                   then 'Volante'
               when sga_propuestas.nombre ilike '%curso%'
                   then 'Curso de ingreso'
               when sga_propuestas.nombre ilike '%psicopedag%'
                   then 'Psicopedagogía' 
               when sga_propuestas.nombre ilike '%tecnicatu%'
                   then 'Tecnicatura' 
               when sga_propuestas.nombre ilike '%traducto%'
                   then 'Traductorado'                    
               else 'Profesorado'
               end as "propuesta_tipo_segun_nombre_propuesta",
           sga_tipos_ingreso.nombre as "propuesta_tipo_segun_cualidad_ingreso",    
           CASE 
               when sga_propuestas.nombre like 'N3 - Actualización Académica en Educación Ambiental Integral y Enseñanza de las Ciencias en%'
                   then 'N3 - Actualización Académica en Educación Ambiental Integral y Enseñanza de las Ciencias en el Nivel Primario'
               when sga_propuestas.nombre like 'N4 - Especialización Docente de Nivel Superior en Enseñanza de las Ciencias Sociales en la Ed%'
                   then 'N4 - Especialización Docente de Nivel Superior en Enseñanza de las Ciencias Sociales en la Educación Primaria'
               else sga_propuestas.nombre
               end as "propuesta_nombre",
           sga_preinscripcion_propuesta.fecha_preinscripcion as "preinsc_propuesta_fecha",
           sga_propuestas_aspira.fecha_inscripcion as "insc_propuesta_fecha",
           sga_propuestas_aspira.anio_academico as "insc_propuesta_anio_academico",
           case
               when sga_periodos_inscripcion.periodo_generico_tipo  = '4'
                   then 'inscripcion_propuesta'
               else 'error'
               end as "insc_propuesta_tipo_generico_periodo_lectivo",
           sga_periodos_inscripcion.nombre as "insc_propuesta_periodo_lectivo"        
    from negocio.sga_alumnos
             left join mdp_personas on sga_alumnos.persona = mdp_personas.persona
             left join ( select persona, email
                         from negocio.mdp_personas_contactos
                         where contacto_tipo = 'MP'
                         group by persona, email
                         order by persona
    ) as mdp_personas_contactos on mdp_personas.persona = mdp_personas_contactos.persona
             left join sga_ubicaciones on sga_alumnos.ubicacion  = sga_ubicaciones.ubicacion
             left join sga_propuestas on sga_alumnos.propuesta = sga_propuestas.propuesta
             left join sga_propuestas_tipos on sga_propuestas.propuesta_tipo = sga_propuestas_tipos.propuesta_tipo
             left join sga_preinscripcion_propuesta on mdp_personas.persona = sga_preinscripcion_propuesta.persona and
                                                       sga_propuestas.propuesta = sga_preinscripcion_propuesta.propuesta
             left join sga_propuestas_aspira on mdp_personas.persona = sga_propuestas_aspira.persona and
                                                sga_propuestas.propuesta = sga_propuestas_aspira.propuesta
             left join sga_periodos_inscripcion_fechas on sga_propuestas_aspira.periodo_insc = sga_periodos_inscripcion_fechas.periodo_insc
             left join sga_periodos_inscripcion on sga_periodos_inscripcion_fechas.periodo_inscripcion = sga_periodos_inscripcion.periodo_inscripcion
             left join sga_situacion_aspirante on sga_propuestas_aspira.situacion_asp = sga_situacion_aspirante.situacion_asp
             left join sga_tipos_ingreso on sga_propuestas_aspira.tipo_ingreso = sga_tipos_ingreso.tipo_ingreso
    where sga_situacion_aspirante.situacion_asp not in ('3', '4', '5', '6', '7') and
          (sga_periodos_inscripcion.nombre in (
                                                 'ELIMINADO POR PRIVACIDAD') 
                 )), 
-- query_insc_mat
     query_insc_mat AS (
         select sga_alumnos.alumno,
                ROW_NUMBER() OVER (PARTITION BY sga_alumnos.alumno, sga_elementos.nombre, sga_periodos.nombre ORDER BY sga_periodos.fecha_inicio DESC) AS "gradiente_materia_y_period_insc_materia_por_fecha",
                ROW_NUMBER() OVER (PARTITION BY sga_alumnos.alumno, sga_elementos.nombre ORDER BY sga_periodos.fecha_inicio DESC) AS "gradiente_materia_por_fecha",
                sga_insc_cursada.estado as "estado_insc_materia",
                case
                    when lower(sga_elementos.codigo) like 'ci%'
                       then 'Curso de ingreso'
                    else 'materia'
                    end as "materia_tipo_segun_nombre_materia",
                case
                    when sga_elementos.nombre like 'El Nivel Pragmático Discursivo de la Lengua Adicional Inglés y sus Implicancias para la Selección y el Análisis de los Textos a Enseñar%'
                        then 'El Nivel Pragmático Discursivo de la Lengua Adicional Inglés'
                    else sga_elementos.nombre
                    end as "materia_nombre",
                replace(sga_comisiones.nombre, ';' , ',') as "comision_nombre",
                sga_comisiones.turno as "comision_turno",
                sga_periodos.fecha_inicio as "insc_materia_fecha",
                sga_periodos.anio_academico as "insc_materia_anio_academico",
                sga_periodos_genericos_tipos.nombre as "insc_materia_tipo_generico_periodo_lectivo",
                case
                    when sga_periodos.nombre ilike '%curso de ing%'
                        then 'Curso de ingreso'
                    when sga_periodos.nombre ilike '%verano%'
                        then 'Curso de verano'
                    else 'periodo_comun'
                    end as "insc_materia_tipo_periodo_lectivo",
                sga_periodos.nombre as "insc_materia_periodo_lectivo",
                sga_periodos_genericos.periodo_lectivo_tipo as "insc_materia_duracion_comision"
         from negocio.sga_alumnos
                  left join sga_insc_cursada on sga_alumnos.alumno = sga_insc_cursada.alumno
                  left join sga_comisiones on sga_insc_cursada.comision = sga_comisiones.comision
                  left join sga_elementos on sga_comisiones.elemento = sga_elementos.elemento
                  left join sga_periodos_lectivos on sga_comisiones.periodo_lectivo = sga_periodos_lectivos.periodo_lectivo
                  left join sga_periodos on sga_periodos_lectivos.periodo = sga_periodos.periodo
                  left join sga_periodos_genericos on sga_periodos.periodo_generico = sga_periodos_genericos.periodo_generico
                  left join sga_periodos_genericos_tipos on sga_periodos_genericos.periodo_generico_tipo = sga_periodos_genericos_tipos.periodo_generico_tipo
         where sga_elementos.nombre is not null and
               sga_periodos.nombre in (
                                     'ELIMINADO POR PRIVACIDAD') and
                sga_periodos.anio_academico = '2024' and                      
                lower(sga_elementos.codigo) not like 'ci%'                     
             ),
-- query_todos_result_mat
     query_todos_result_mat as (
         select sga_alumnos.alumno,
                sga_alumnos_1.alumno as "alumno_1",
                sga_elementos.nombre as "materia_nombre",
                sga_elementos.codigo as "materia_codigo",
                sga_planes_versiones_result.plan_version as "plan_version_sga_alumnos_1",
                case
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) in
                         ('A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9l', 'A1000')
                        then 'Aprobado por examen'
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) = 'A2'
                        then 'Aprobado por promocion'
                    when concat(sga_instancias.instancia) = '10'
                        then 'Aprobado por equivalencia'
                    when concat(sga_instancias.instancia) = '13'
                        then 'Aprobado por resolucion'
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) = 'A1'
                        then 'Regular'
                    when concat(sga_instancias.instancia) in ('11', '12', '14')
                        then 'Regular por equivalencia'
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) like 'R%'
                        then 'Reprobado - Insuficiente'
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) like 'U%'
                        then 'Ausente - Libre - Abandono'
                    else 'Error'
                    end as "materia_resultado",
                case
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) in
                         ('A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9', 'A1000')
                        then 1
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) = 'A2'
                        then 2
                    when concat(sga_instancias.instancia) = '10'
                        then 3
                    when concat(sga_instancias.instancia) = '13'
                        then 4
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) = 'A1'
                        then 5
                    when concat(sga_instancias.instancia) in ('11', '12', '14')
                        then 6
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) like 'R%'
                        then 7
                    when concat(sga_actas_detalle.resultado, sga_instancias.instancia) like 'U%'
                        then 8
                    else 9
                    end as "materia_resultado_num",
                sga_escalas_notas_det.nota as "materia_resultado_nota",
                sga_periodos.anio_academico as "materia_resultado_anio_academico",
                sga_periodos.nombre as "insc_resultado_materia_periodo_lectivo",
                case
                    when sga_instancias.instancia in ('1','2','3','4','5','6','7','8','9','1000') --fecha_cursada
                        then sga_actas_detalle.fecha
                    when sga_instancias.instancia in ('10','11','12','14') --fecha_equivalencia
                        then sga_equiv_tramite.fecha
                    when sga_instancias.instancia = '13' --fecha_aprob_p_resolucion
                        then sga_reconocimiento.fecha
                    else null
                    end as "insc_resultado_materia_fecha"
         from negocio.sga_instancias
                  left join sga_actas_detalle on sga_instancias.instancia = sga_actas_detalle.instancia
                  left join sga_actas on sga_actas_detalle.id_acta = sga_actas.id_acta
                  left join sga_comisiones on sga_actas.comision = sga_comisiones.comision
                  left join sga_periodos_lectivos on sga_comisiones.periodo_lectivo = sga_periodos_lectivos.periodo_lectivo
                  left join sga_llamados_mesa on sga_actas.llamado_mesa = sga_llamados_mesa.llamado_mesa
                  left join sga_mesas_examen on sga_llamados_mesa.mesa_examen = sga_mesas_examen.mesa_examen
                  left join sga_llamados_turno on sga_llamados_mesa.llamado = sga_llamados_turno.llamado
                  left join sga_periodos on sga_periodos_lectivos.periodo = sga_periodos.periodo or
                                            sga_llamados_turno.periodo = sga_periodos.periodo
                  left join sga_periodos_genericos on sga_periodos.periodo_generico = sga_periodos_genericos.periodo_generico
                  left join sga_equiv_otorgada on sga_instancias.instancia = sga_equiv_otorgada.instancia
                  left join sga_equiv_tramite on sga_equiv_otorgada.equivalencia_tramite  = sga_equiv_tramite.equivalencia_tramite
                  left join sga_escalas_notas_instancias on sga_instancias.instancia = sga_escalas_notas_instancias.instancia and
                                                            sga_escalas_notas_instancias.instancia = '13'
                  left join sga_reconocimiento_act on sga_escalas_notas_instancias.escala_nota = sga_reconocimiento_act.escala_nota
                  left join sga_reconocimiento on sga_reconocimiento_act.nro_tramite  = sga_reconocimiento.nro_tramite
                  left join sga_alumnos sga_alumnos_1 on
             sga_actas_detalle.alumno = sga_alumnos_1.alumno or
             sga_equiv_tramite.alumno = sga_alumnos_1.alumno or
             sga_reconocimiento.alumno = sga_alumnos_1.alumno
                  join negocio.sga_alumnos on sga_alumnos_1.persona = sga_alumnos.persona
                  left join sga_elementos on
             sga_comisiones.elemento = sga_elementos.elemento or
             sga_mesas_examen.elemento = sga_elementos.elemento or
             sga_equiv_otorgada.elemento = sga_elementos.elemento or
             sga_reconocimiento_act.elemento = sga_elementos.elemento
                  left join negocio.sga_elementos_revision on sga_elementos_revision.elemento = sga_elementos.elemento
                  left join negocio.sga_planes_versiones sga_planes_versiones_sga_alumnos on sga_planes_versiones_sga_alumnos.plan_version = sga_alumnos.plan_version
                  left join negocio.sga_planes_versiones sga_planes_versiones_result on sga_planes_versiones_result.plan_version = sga_actas_detalle.plan_version or
                                                                                        sga_planes_versiones_result.plan_version = sga_equiv_tramite.plan_version or
                                                                                        sga_planes_versiones_result.plan_version = sga_reconocimiento.plan_version
                  left join negocio.sga_elementos_plan on (sga_elementos_plan.plan_version = sga_actas_detalle.plan_version or
                                                           sga_elementos_plan.plan_version = sga_equiv_tramite.plan_version or
                                                           sga_elementos_plan.plan_version = sga_reconocimiento.plan_version) and
                                                          sga_elementos_plan.elemento_revision = sga_elementos_revision.elemento_revision
                  left join sga_escalas_notas_det on
             sga_actas_detalle.nota = sga_escalas_notas_det.nota and sga_actas_detalle.escala_nota = sga_escalas_notas_det.escala_nota or
             sga_equiv_otorgada.nota = sga_escalas_notas_det.nota and sga_equiv_otorgada.escala_nota = sga_escalas_notas_det.escala_nota or
             sga_reconocimiento_act.nota = sga_escalas_notas_det.nota and sga_reconocimiento_act.escala_nota = sga_escalas_notas_det.escala_nota
         where (((sga_actas_detalle.estado = 'A' and
                  sga_actas.estado != 'B') or
                 (sga_equiv_tramite.estado != 'B' and
                  sga_equiv_otorgada.resultado = 'A' and
                  sga_equiv_otorgada.estado = 'A') or
                 (sga_reconocimiento.estado != 'B' and
                  sga_reconocimiento_act.estado = 'A')) and
                ((sga_alumnos.alumno = sga_alumnos_1.alumno) or
                 (sga_alumnos.plan_version in
                  (select sga_elementos_plan.plan_version
                   from negocio.sga_elementos_plan
                   where sga_elementos_plan.elemento_revision = sga_elementos_revision.elemento_revision)) and
                 (NOT (EXISTS ( SELECT 1
                                FROM negocio.sga_elementos_no_comunes
                                WHERE sga_elementos_no_comunes.plan_origen = sga_planes_versiones_result.plan AND
                                    sga_elementos_no_comunes.plan_destino = sga_planes_versiones_sga_alumnos.plan AND
                                    sga_elementos_no_comunes.elemento = sga_elementos.elemento)))))),
-- query_todos_result_mat_1
     query_todos_result_mat_1 as (
         select alumno,
                ROW_NUMBER() OVER (PARTITION BY alumno, materia_nombre, insc_resultado_materia_periodo_lectivo ORDER BY materia_resultado_num asc) AS "gradiente_materia_y_periodo_result_materia_por_result_materia",
                ROW_NUMBER() OVER (PARTITION BY alumno, materia_nombre ORDER BY materia_resultado_num asc, insc_resultado_materia_fecha DESC) AS "gradiente_materia_por_result_materia_y_fecha",
                case
                    when materia_nombre like 'El Nivel Pragmático Discursivo de la Lengua Adicional Inglés y sus Implicancias para la Selección y el Análisis de los Textos a Enseñar%'
                        then 'El Nivel Pragmático Discursivo de la Lengua Adicional Inglés'
                    else materia_nombre
                    end as "materia_nombre",
                materia_codigo,    
                materia_resultado,
                case
                    when max(
                         case when alumno_1 != alumno and
                                   materia_nombre not like '%ntroduc%' and
                                   materia_nombre not like '%ngres%' and
                                   materia_nombre not like 'Curso%' and
                                   insc_resultado_materia_periodo_lectivo not in ('Curso de Ingreso 2024 Artísticas (Periodo Diciembre 2023)',
                                                                                  'Curso de Ingreso 2024 Normales y Artísticas (Periodo Febrero/Marzo 2024)',
                                                                                  'FA - Curso de Ingreso 2024 (Periodo Diciembre 2023)') and
                                   materia_resultado in ('Aprobado por examen',
                                                         'Aprobado por promocion',
                                                         'Aprobado por equivalencia',
                                                         'Aprobado por resolucion',
                                                         'Regular',
                                                         'Regular por equivalencia') then 1 else 0 end)
                         OVER (PARTITION BY alumno, alumno_1, materia_nombre) = 1
                        then 1
                    else 0
                    end as "materia_resultado_aprob_equiv_automatica",
                materia_resultado_nota,
                materia_resultado_anio_academico,
                insc_resultado_materia_periodo_lectivo,
                insc_resultado_materia_fecha,
                case
                    when max(
                         case when alumno_1 != alumno and
                                   materia_nombre not like '%ntroduc%' and
                                   materia_nombre not like '%ngres%' and
                                   materia_nombre not like 'Curso%' and
                                   insc_resultado_materia_periodo_lectivo not in ('Curso de Ingreso 2024 Artísticas (Periodo Diciembre 2023)',
                                                                                  'Curso de Ingreso 2024 Normales y Artísticas (Periodo Febrero/Marzo 2024)',
                                                                                  'FA - Curso de Ingreso 2024 (Periodo Diciembre 2023)') and
                                   materia_resultado in ('Aprobado por examen',
                                                         'Aprobado por promocion',
                                                         'Aprobado por equivalencia',
                                                         'Aprobado por resolucion',
                                                         'Regular',
                                                         'Regular por equivalencia') then 1 else 0 end)
                         OVER (PARTITION BY alumno) = 1
                        then 1
                    else 0
                    end as "alumno_con_equiv_automatica",
                case
                    when max(
                         case when materia_resultado = 'Aprobado por equivalencia' or
                                   materia_resultado = 'Aprobado por resolucion' then 1 else 0 end)
                         OVER (PARTITION BY alumno) = 1
                        then 1
                    else 0
                    end as "alumno_con_aprob_por_equiv_o_resol"
         from query_todos_result_mat
         order by alumno,
                  materia_nombre),
-- query_todos_result_mat_2
     query_todos_result_mat_2 as (
         select alumno,
                gradiente_materia_y_periodo_result_materia_por_result_materia,
                gradiente_materia_por_result_materia_y_fecha,
                materia_nombre,
                materia_resultado,
                materia_resultado_aprob_equiv_automatica,
                materia_resultado_nota,
                materia_resultado_anio_academico,
                insc_resultado_materia_periodo_lectivo,
                insc_resultado_materia_fecha
         from query_todos_result_mat_1
         where insc_resultado_materia_periodo_lectivo in (
                                                          'ELIMINADO POR PRIVACIDAD') and
                materia_resultado_anio_academico = '2024' and                                           
                lower(materia_codigo) not like 'ci%'                                                     
             ),
-- query_todos_result_mat_equiv
     query_todos_result_mat_equiv as (
         select alumno,
                alumno_con_equiv_automatica,
                alumno_con_aprob_por_equiv_o_resol
         from query_todos_result_mat_1
         group by alumno,
                  alumno_con_equiv_automatica,
                  alumno_con_aprob_por_equiv_o_resol),
-- query_result_cursada
     query_result_cursada as (
         select *
         from query_todos_result_mat_2
         where gradiente_materia_y_periodo_result_materia_por_result_materia = '1'),
				-- QUERY_RESULT_CURSADA_EXAMEN_MAX
				--query_result_cursada_examen_max as (
				--select *
				--from query_todos_result_mat_2
				--where gradiente_materia_por_result_materia_y_fecha = '1'),
-- query_insc_mat_2
     query_insc_mat_2 as (
         select *
         from query_insc_mat
         where gradiente_materia_y_period_insc_materia_por_fecha = '1'),
-- join_query_insc_mat_2_y_query_result_cursada
     join_query_insc_mat_2_y_query_result_cursada AS(
         select coalesce (query_insc_mat_2.alumno, query_result_cursada.alumno) as "alumno",
                query_insc_mat_2.gradiente_materia_y_period_insc_materia_por_fecha,
                --query_insc_mat_2.gradiente_materia_por_fecha,
                query_insc_mat_2.estado_insc_materia,
                query_insc_mat_2.materia_tipo_segun_nombre_materia,
                coalesce (query_insc_mat_2.materia_nombre, query_result_cursada.materia_nombre) as "materia_nombre",
                query_insc_mat_2.comision_nombre,
                query_insc_mat_2.comision_turno,
                query_insc_mat_2.insc_materia_fecha,
                query_insc_mat_2.insc_materia_anio_academico,
                query_insc_mat_2.insc_materia_tipo_periodo_lectivo,
                query_insc_mat_2.insc_materia_periodo_lectivo,
                query_insc_mat_2.insc_materia_duracion_comision,
                query_result_cursada.materia_resultado,
                query_result_cursada.materia_resultado_aprob_equiv_automatica,
                query_result_cursada.materia_resultado_nota,
                query_result_cursada.materia_resultado_anio_academico,
                query_result_cursada.insc_resultado_materia_periodo_lectivo,
                query_result_cursada.insc_resultado_materia_fecha
         from query_insc_mat_2
                  full outer join query_result_cursada on query_insc_mat_2.alumno = query_result_cursada.alumno and
                                                          query_insc_mat_2.materia_nombre = query_result_cursada.materia_nombre and
                                                          query_insc_mat_2.insc_materia_periodo_lectivo = query_result_cursada.insc_resultado_materia_periodo_lectivo),
-- join_q_ins_prop_y_j_q_ins_mat_y_q_res_curs_y_q_todos_res_mat_eq
     join_q_ins_prop_y_j_q_ins_mat_y_q_res_curs_y_q_todos_res_mat_eq as(
         select coalesce (query_insc_prop.alumno, join_query_insc_mat_2_y_query_result_cursada.alumno) as "alumno",
                query_insc_prop.persona,
                query_insc_prop.dni,
                query_insc_prop.email,
                query_insc_prop.calidad,
                query_insc_prop.alumno_regular,
                query_insc_prop.alumno_cant_readmisiones,
                query_insc_prop.ubicacion,
                query_insc_prop.estado_insc_propuesta,
                query_insc_prop.nivel_propuesta_segun_periodo_insc_propuesta,
                query_insc_prop.propuesta_tipo_segun_nombre_propuesta,
                query_insc_prop.propuesta_tipo_segun_cualidad_ingreso,
                query_insc_prop.propuesta_nombre,
                query_insc_prop.preinsc_propuesta_fecha,
                query_insc_prop.insc_propuesta_fecha,
                query_insc_prop.insc_propuesta_anio_academico,
                query_insc_prop.insc_propuesta_periodo_lectivo,
                join_query_insc_mat_2_y_query_result_cursada.gradiente_materia_y_period_insc_materia_por_fecha,
                join_query_insc_mat_2_y_query_result_cursada.estado_insc_materia,
                join_query_insc_mat_2_y_query_result_cursada.materia_tipo_segun_nombre_materia,
                join_query_insc_mat_2_y_query_result_cursada.materia_nombre,
                join_query_insc_mat_2_y_query_result_cursada.comision_nombre,
                join_query_insc_mat_2_y_query_result_cursada.comision_turno,
                join_query_insc_mat_2_y_query_result_cursada.insc_materia_fecha,
                join_query_insc_mat_2_y_query_result_cursada.insc_materia_anio_academico,
                join_query_insc_mat_2_y_query_result_cursada.insc_materia_tipo_periodo_lectivo,
                join_query_insc_mat_2_y_query_result_cursada.insc_materia_periodo_lectivo,
                join_query_insc_mat_2_y_query_result_cursada.insc_materia_duracion_comision,
                join_query_insc_mat_2_y_query_result_cursada.materia_resultado,
                join_query_insc_mat_2_y_query_result_cursada.materia_resultado_aprob_equiv_automatica,
                join_query_insc_mat_2_y_query_result_cursada.materia_resultado_nota,
                join_query_insc_mat_2_y_query_result_cursada.materia_resultado_anio_academico,
                join_query_insc_mat_2_y_query_result_cursada.insc_resultado_materia_periodo_lectivo,
                join_query_insc_mat_2_y_query_result_cursada.insc_resultado_materia_fecha,
                query_todos_result_mat_equiv.alumno_con_equiv_automatica,
                query_todos_result_mat_equiv.alumno_con_aprob_por_equiv_o_resol                
         from query_insc_prop
                  left join join_query_insc_mat_2_y_query_result_cursada on
             query_insc_prop.alumno = join_query_insc_mat_2_y_query_result_cursada.alumno
                  left join query_todos_result_mat_equiv on
             query_insc_prop.alumno = query_todos_result_mat_equiv.alumno)
--
select *
from join_q_ins_prop_y_j_q_ins_mat_y_q_res_curs_y_q_todos_res_mat_eq;

