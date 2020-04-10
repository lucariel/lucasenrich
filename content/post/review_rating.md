Este proyecto, en principio, emula bastante el realizado para un
cliente, quien necesitaba calificar las reviews que generaban los
callcenter, las cuales una parte estaba calificada y otra parte no.

Por razones obvias, se usa un dataset de reviews de hoteles para lograr
el mismo objetivo.

En principio, lo que se va a ver es las calificaciones haciendo uso de
Doc2Vec para convertir el texto en un vector numerico y poder, con esos
vectores numericos como input, realizar la predicción de cual sería la
calificación que hubiera tenido según el texto. Haciendo uso de
algortimos de aprendizaje supervisado y ensamblado de varios.

Por otro lado, dado que los datos no son tantos, lo que perjudica la
construcción del vector numerico a partir de los textos, se hará uso de
un "word embedding" ya entrenado y posteriormente se verá como mejora el
poder predictivo.

(datos en /media/lucariel/Cosas/Proyectos/tr/tecnologia5)

### Los datos y la limpieza

Para empezar, veamos como se ven los datos:

<table style="width:39%;">
<colgroup>
<col width="16%" />
<col width="22%" />
</colgroup>
<thead>
<tr class="header">
<th>review.rating</th>
<th>review.text</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>5</td>
<td>Our experience at Rancho Valencia was absolutely perfect from beginning to end!!!! We felt special and very happy during our stayed. I would come back in a heart beat!!!</td>
</tr>
<tr class="even">
<td>5</td>
<td>Amazing place. Everyone was extremely warm and welcoming. We've stayed at some top notch places and this is definitely in our top 2. Great for a romantic getaway or take the kids along as we did. Had a couple stuffed animals waiting for our girls upon arrival. Can't wait to go back.</td>
</tr>
<tr class="odd">
<td>2</td>
<td>We booked a 3 night stay at Rancho Valencia to play some tennis, since it is one of the highest rated tennis resorts in America. This place is really over the top from a luxury standpoint and overall experience. The villas are really perfect, the staff is great, attention to details (includes fresh squeezed orange juice each morning), restaurants, bar and room service amazing, and the tennis program was really impressive as well. We will want to come back here again.</td>
</tr>
</tbody>
</table>

En lugar de importar todos los paquetes juntos, vamos a ir importando a
medida que vayamos necesitando.

    import pandas as pd
    cc = pd.read_csv('./hotel-reviews/Datafiniti_Hotel_Reviews.csv')

Vamos a seleccionar las columnas necesarias y cambiarle el nombre para
que sea mas facil luego seleccionarlas.

    cc = cc[['reviews.title','reviews.text','reviews.rating']]
    cc.columns = ['titulo','comentarios','calificacion']

El primer paso a la hora de trabajar con estos textos, es reducir a la
maxima expresión la cardinalidad del vocabulario. ¿Que significa esto?
Si tenemos una gran cantidad de usos de un verbo, como por ejemplo,
"correr" en sus distintas conjugaciones, "corría","corriendo","corrian"
y queremos armar un listado de frecuencias de palabras, esto daria como
resultado que cada uno de esas palabras aparezca una sola vez; pero si
logramos que la referencia a la acción concreta de "correr" sume
independientemente de su conjugación, reduciríamos la cardinalidad de
nuestro diccionario, eso es para lo que se usa la *lematización*.

<table>
<thead>
<tr class="header">
<th>Original</th>
<th>Lemmatizacion</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>corrian</td>
<td>correr</td>
</tr>
<tr class="even">
<td>corriendo</td>
<td>correr</td>
</tr>
<tr class="odd">
<td>corrio</td>
<td>correr</td>
</tr>
</tbody>
</table>

Luego, hay sustantivos y otras palabras que tienen la misma raiz y
dependiendo del sujeto, se puede reducir el tamaño del diccionario
cortando de la raiz la palabra, lo que se conoce como *stemmización*

<table>
<thead>
<tr class="header">
<th>Original</th>
<th>Stemmización</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>niña</td>
<td>niñe</td>
</tr>
<tr class="even">
<td>niño</td>
<td>niñe</td>
</tr>
<tr class="odd">
<td>niñe</td>
<td>niñe</td>
</tr>
</tbody>
</table>

El proceso de lematización y stemización, en su conjunto, se puede
entender como normalizar el vocabulario y por lo tanto, una función que
se encarge de hacer estas dos cosas, puede llamarse *normalize(text)*:

    def normalize(text):
        from nltk.stem import PorterStemmer
        from nltk.tokenize import word_tokenize
        import unidecode
        import spacy
        nlp = spacy.load('en_core_web_sm')
        porter = PorterStemmer()
        doc = nlp(text)
        lemmas = [unidecode.unidecode(tok.lemma_.lower()) for tok in doc if not tok.is_punct ]
        #En este caso, estoy eliminando palabras con menos de 3 letras y las negaciones, esto no es necesario estrictamente, y depende mucho del caso de aplicación, a veces funciona, a veces no.
        lexical_tokens = [t.lower() for t in lemmas if (len(t) > 3 or t =="no") and t.isalpha()]
        lexical_tokens = [porter.stem(t) for t in lexical_tokens]
        return lexical_tokens

Esta funcion tiene como input una frace y escupe objeto tipo list()
asique lo que haré es aplicarla a cada texto y despues volverla a unir
para que cada fila tenga un texto y no un array

    norm_token = []
    for i in range(len(cc.comentarios)):
        try:
            a = normalize(cc.comentarios[i])
        except:
            a = ''
        norm_token.append(a)
    norm_text = [' '.join(x) for x in norm_token]
    cc['norm_text'] = norm_text

¿Porque no tratar directo con los tokens? Por la sencilla razón hay un
paquete que permite aplicar Doc2Vec, asociando un texto a una clase,
*gensim* nos va a venir bien para esto:

    from gensim.models.doc2vec import Doc2Vec, TaggedDocument
    #Primera la separacion entre test y train
    train, test = train_test_split(cc, test_size=0.2, random_state=42)

    train_tagged = train.apply(
        lambda r: TaggedDocument(words=word_tokenize(r.norm_text), tags=[r.calificacion]), axis=1)
    test_tagged = test.apply(
        lambda r: TaggedDocument(words=word_tokenize(r.norm_text), tags=[r.calificacion]), axis=1)

Una vez que tenemos los elementos de train y test, hay que entrenar el
Doc2Vec, para, así pasar el texto a un vector númerico que pueda ser el
input del algoritmo de clasificación

    for epoch in range(30):

        model_dbow.train(utils.shuffle([x for x in tqdm(train_tagged.values)]), total_examples=len(train_tagged.values), epochs=1)
        model_dbow.alpha -= 0.002
        model_dbow.min_alpha = model_dbow.alpha

Con el modelo Doc2Vec entrenado, podemos darle pasar los textos y
obtener el vector numerico deseado. Ahora bien, para facilitar la
implementación del modelo después, generemos una función con dos ouputs,
el vector numerico por un lado, y el rating asociado a ese vector
numérico

    def vec_for_learning(model, tagged_docs):
        sents = tagged_docs.values
        targets, regressors = zip(*[(doc.tags[0], model.infer_vector(doc.words, steps=20)) for doc in sents])
        return targets, regressors
