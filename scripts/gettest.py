from langchain_community.chat_models import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate

def generate_test_code(moonbit_code,path,api_key):
    test_prompt = ChatPromptTemplate.from_template(
        """作为一名MoonBit语言工程师，你的任务是编写一系列测试用例来验证项目的正确性。
        请根据以下提供的格式，结合文件名{path}理解函数的用途，对给出的MoonBit函数编写对应的测试用例,
        以下是你需要提供的测试用例格式参考：
       test {{
        assert_eq!(f(x))
        assert_eq!(f(x))
          }}
        需要提供测试用例的MoonBit函数为{moonbit_code}。
        注意，你的输出中只需要包含测试用例的代码，不需要包括分析过程以及任何其他语句。
        同时，你生成的是moonbit语言的测试用例，请不要将moonbit语言与其他语言混淆
        """
    )

    test_llm = ChatZhipuAI(
        api_key=api_key,
        model="glm-4-plus",
        temperature=0.5,
        max_tokens=2048
    )

    test_retriever_chain = (
        test_prompt
        | test_llm
        | StrOutputParser()
    )
    test_code = test_retriever_chain.invoke({
        "moonbit_code": moonbit_code,
        "path":path
    })
    return test_code