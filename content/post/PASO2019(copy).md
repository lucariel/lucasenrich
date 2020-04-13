Review Rating
==================

¿Cómo generar un puntaje númerico en base a un texto?

Mucho de lo expuesto es en realidad distintas formas de pensar el
problema y quedarse con la mejor solución. 

Paseo por Doc2Vec, Regresiones lineales, randomForests y redes convolutivas
con GloVe

<a href="https://lucasenrich.netlify.com/post/review_rating/">Read more </a>

En principio, lo que se va a ver es las calificaciones haciendo uso de
Doc2Vec para convertir el texto en un vector numerico y poder, con esos
vectores numericos como input, realizar la predicción de cual sería la
calificación que hubiera tenido según el texto. Haciendo uso de
algortimos de aprendizaje supervisado.

Por otro lado, dado que los datos no son tantos, lo que perjudica la
construcción del vector numerico a partir de los textos, se hará uso de
un "word embedding" ya entrenado y posteriormente se verá como mejora el
poder predictivo.




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

### Doc2Vec: Generando el embedding numérico

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

Ahora que tenemos la función que nos genera el vector númerico
terminamos con el proceso de preparación de los datos. Es curioso notar
que siempre se dice que el 80% del trabajo consiste en la preparación y
limpieza de datos, y el 20% el modelado. Hasta ahora se puede ver que no
es una distinción tan discreta, sino que es continua. ¿A qué me refiero?
Bueno, para preparar los datos hizo falta algoritmos de embedding
(Doc2Vec). Y no es poco común que ocurran estas cosas.

Ahora bien, volvamos a lo nuestro, es hora de correr los algoritmos de
regresión:

### Regresión

    from sklearn.ensemble import RandomForestRegressor
    from sklearn.linear_model import LinearRegression

    y_train, X_train = vec_for_learning(model_dbow, train_tagged)
    y_test, X_test = vec_for_learning(model_dbow, test_tagged)

    lr = LinearRegression()
    lr.fit(X_train, y_train)
    y_pred = lr.predict(X_test)

    print(np.sqrt(mean_squared_error(y_test, y_pred))) #1.15

Este resultado no me convence demasiado si consideramos al puntaje como
una regresión. El error cuadratico medio es del 1.15pts, para los que no
recuerdan, el error cuadratico medio toma la diferencia entre el valor
predecido y el valor real, lo eleva al cuadrado y de ello toma el
promedio. Les dejo un <a href="https://www.youtube.com/watch?v=8wgy8Vopv3E">video </a> de mi canal de Youtube con la visualización
de lo que significa



### Clasificación

Otra forma de entender el problema es como uno de clasificación. ¿Pero
como pasamos de un target continuo a uno discreto? Podríamos pensar que
los puntajes de 4 ó 5 son "buenos", y asignarles un 1, y los de menos de
4 son "malos", y asignarles un 0, y nos quedamos con un problema de
clasificación binaria.

Además, con estas conceptualización, tenes que volver a correr el
embedding porque los "tags" no son ahora los puntajes del 1 al 5 sino
que son {1,0}

    cl = []
    for i in cc.calificacion:
        if i <4:
            cl.append(0)
        else:
            cl.append(1)
    cc.calificacion = cl

    train, test = train_test_split(cc, test_size=0.2, random_state=42)

    train_tagged = train.apply(
        lambda r: TaggedDocument(words=word_tokenize(r.norm_text), tags=[r.calificacion]), axis=1)
    test_tagged = test.apply(
        lambda r: TaggedDocument(words=word_tokenize(r.norm_text), tags=[r.calificacion]), axis=1)
    model_dbow = Doc2Vec(dm=0, vector_size=300, negative=5, hs=0, min_count=2, sample = 0)
    model_dbow.build_vocab([x for x in tqdm(train_tagged.values)])
    for epoch in range(30):
        model_dbow.train(utils.shuffle([x for x in tqdm(train_tagged.values)]), total_examples=len(train_tagged.values), epochs=1)
        model_dbow.alpha -= 0.002
        model_dbow.min_alpha = model_dbow.alpha

Ahora si, sacamos los vectores del modelo Doc2Vec y lo fiteamos a un
randomForest clasificador:

    from sklearn.ensemble import RandomForestClassifier
    y_train, X_train = vec_for_learning(model_dbow, train_tagged)
    y_test, X_test = vec_for_learning(model_dbow, test_tagged)


    rfr = RandomForestClassifier(n_estimators = 500, random_state = 42)
    rfr.fit(X_train, y_train)

¿Cómo evaluamos esta clasificación? Bueno, primero nos fijamos cuanto
coincide la predicción respecto al valor real, para eso se usa la matriz
de confusión

    from sklearn.metrics import confusion_matrix
    y_pred = rfr.predict(X_test)
    tn, fp, fn, tp = confusion_matrix(y_test, y_pred, labels=[0,1]).ravel()


    np.mean(y_test == y_pred)

Nuestra precisión es del 72,4%, nada mal, solo un detalle. Si mandamos
un modelo que siempre diga "1", tendremos una precisión equivalente a la
proporción de "1" en el set. Que en la base completa es de 72,8%. Es
decir, este modelo no mejor que decir que todas son igual a "1".

### Polaridad como métrica

Otra alternativa puede ser extraer la polaridad del texto, herramienta
muy útil en los procesos de sentiment analysis. Y podríamos pensar que,
cuan más positivo sea la polaridad, estará asociado a un mejor puntaje

    from textblob import TextBlob 
    pls = []
    sbj = []
    for i in range(len(cc.comentarios)):
        try:
            senti = TextBlob(cc.comentarios[i]) 
            polarity = senti.sentiment
            pls.append(polarity[0])
            sbj.append(polarity[1])
        except:
            pls.append(0)
            sbj.append(0)
            

    polscore = [int(x > 0) for x in pls] # Acá 0 es un valor arbitrario de corte, 
    #un ejericio podría incluir la optimización de este valor como un hiperparametro. 
    #La polaridad genera un indice de -1, 1. Siendo -1 cuan más negativo es, y 1 cuan más #positivo es, y polscore dice que aquellos que tienen valoracion positiva sean 1 y los demás 0
    np.mean(polscore == np.array(cc.calificacion))

Sirve esto? Y, esto esta dando un resultado de 78.55%, es, a mi
sorpresa, una mejora respecto al punto anterior. Aunque todavía no es
satisfactorio.

Evidentemente el score de polarización agrega información.

### Redes neuronales y GloVe

Global Vectors ó <a href="https://nlp.stanford.edu/projects/glove/">GloVe </a> es una tecnica que, a diferencia de Doc2Vec, que
es un algortimo supervisado, es no-supervisado y obtiene embedings
númericos de palabras según estadisticas de co-ocurrencia. De esta
manera puede encontrar analogías tales como "los que varón es a mujer,
rey es a reina".



Más allá las <a href="https://towardsdatascience.com/gender-bias-word-embeddings-76d9806a0e17">controversias </a>,
es una herramienta bastante útil para muchos casos

El objetivo de esta sección es ver como, haciendo uso de un modelo de
lenguage pre-existente, se puede usar el proceso de transfer-learning
para incorporar nuestros textos y sus calificaciones y adaptarlo a
nuestras necesidades.

Esto es interesante e importante porque hay muchos modelos de lenguage
que han hecho uso de datasets enormes en hardwares mucho más potentes
que los que podría pagar, que se puede aprovechar

    import os
    import sys
    import numpy as np
    from keras.preprocessing.text import Tokenizer
    from keras.preprocessing.sequence import pad_sequences
    from keras.utils import to_categorical
    from keras.layers import Dense, Input, GlobalMaxPooling1D
    from keras.layers import Conv1D, MaxPooling1D, Embedding
    from keras.models import Model
    from keras.initializers import Constant


    BASE_DIR = os.getcwd()
    GLOVE_DIR = os.path.join(BASE_DIR, 'glove.6B') #Este es el modelo pre-entrenado
    TEXT_DATA_DIR = os.path.join(BASE_DIR, '20_newsgroup')
    MAX_SEQUENCE_LENGTH = 1000 #entrenar sobre oraciones de hasta estas palabras
    MAX_NUM_WORDS = 20000 #tamaño máximo del vocabulario
    EMBEDDING_DIM = 300 #dimensión del vector númerico resultante
    VALIDATION_SPLIT = 0.2

    #Volvemos a cargar la información
    import pandas as pd
    cc = pd.read_csv('./hotel-reviews/Datafiniti_Hotel_Reviews.csv')
    cc = cc[['reviews.title','reviews.text','reviews.rating']]
    cc.columns = ['titulo','comentarios','calificacion']

    cl = []
    for i in cc.calificacion:
        if i <4:
            cl.append(0)
        else:
            cl.append(1)
    cc.calificacion=cl

    #Preparación de los datos
    TEXT_DATA_DIR = cc.comentarios

    embeddings_index = {}
    with open(os.path.join(GLOVE_DIR, 'glove.6B.100d.txt')) as f:
        for line in f:
            word, coefs = line.split(maxsplit=1)
            coefs = np.fromstring(coefs, 'f', sep=' ')
            embeddings_index[word] = coefs

    texts = [x for x  in cc.comentarios]  # listado de muestras de texto
    labels_index = {1:1, 2:2, 3:3, 4:4, 5:5}  # diccionario mapeando los revies a los target
    labels = [int(x) for x in cc.calificacion] # target

    # Tokenizar las palabras
    texts = np.array(texts)
    tokenizer = Tokenizer(num_words=MAX_NUM_WORDS)
    tokenizer.fit_on_texts(texts)
    sequences = tokenizer.texts_to_sequences(texts)
    word_index = tokenizer.word_index


    #Con las palabras  tokenizadas, se hace el padding, para que todos tengan la misma longitud, para eso se agrega 0 hasta que se llene
    data = pad_sequences(sequences, maxlen=MAX_SEQUENCE_LENGTH)

    labels = to_categorical(np.asarray(labels))

    indices = np.arange(data.shape[0])
    np.random.shuffle(indices)
    data = data[indices]
    labels = labels[indices]
    num_validation_samples = int(VALIDATION_SPLIT * data.shape[0])

    x_train = data[:-num_validation_samples]
    y_train = labels[:-num_validation_samples]
    x_val = data[-num_validation_samples:]
    y_val = labels[-num_validation_samples:]


    num_words = min(MAX_NUM_WORDS, len(word_index) + 1)
    embedding_matrix = np.zeros((num_words, EMBEDDING_DIM))
    for word, i in word_index.items():
        if i >= MAX_NUM_WORDS:
            continue
        embedding_vector = embeddings_index.get(word)
        if embedding_vector is not None:
            embedding_matrix[i] = embedding_vector

    #Este es el proceso que genera los embeddings
    embedding_layer = Embedding(num_words,
                                EMBEDDING_DIM,
                                embeddings_initializer=Constant(embedding_matrix),
                                input_length=MAX_SEQUENCE_LENGTH,
                                trainable=False)

Ok, hasta ahi la preparación de los datos, es hora de entrenar una red
neuronal convolutiva con los embeddings realizados para obtener el
modelo que clasifique las reiews:

    sequence_input = Input(shape=(MAX_SEQUENCE_LENGTH,), dtype='int32')
    embedded_sequences = embedding_layer(sequence_input)
    x = Conv1D(128, 6, activation='relu')(embedded_sequences)
    x = MaxPooling1D(5)(x)
    x = Conv1D(128, 6, activation='relu')(x)
    x = MaxPooling1D(6)(x)
    x = Conv1D(128, 6, activation='relu')(x)
    x = GlobalMaxPooling1D()(x)
    x = Dense(128, activation='relu')(x)
    preds = Dense(2, activation='softmax')(x)

    model = Model(sequence_input, preds)
    model.compile(loss='categorical_crossentropy',
                  optimizer='rmsprop',
                  metrics=['acc'])

Hay mucho código repetido en este caso, pero eso es para simplicidad de
exposición, lo relevante a enteder es que así se define la capa
convolutiva, que esla que se repite:

    x = Conv1D(128, 6, activation='relu')(embedded_sequences)
    x = MaxPooling1D(5)(x)

Y así la ultima capa, que como terminamos con las "buenas" y "malas"
reviews, tiene una función de activación binaria en el output

    x = Dense(128, activation='relu')(x)
    preds = Dense(2, activation='softmax')(x)

Una vez preparados los datos, y una vez definidas las capas de la red
neuronal se entrena:

    model.fit(x_train, y_train,
              batch_size=128,
              epochs=10,
              validation_data=(x_val, y_val))

Este fit, obtiene un accuracy que supera el 90%. Un gran paso adelante.


