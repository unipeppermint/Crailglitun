import json, pathlib
base=pathlib.Path(__file__).resolve().parents[1]
themes=[('old','旧物档案','时间留在物件里的，一点温柔。','室内'),('window','窗边观察','让光，重新介绍熟悉的角落。','室内'),('color','颜色散步','循着一种颜色，走进日常。','户外'),('shadow','影子地图','记录光路过的形状。','户外'),('geometry','几何日常','在寻常之间，发现秩序。','户外'),('detail','局部世界','靠近一点，世界就不一样。','室内')]
subjects={
'old':[('旧物','旧物的三个瞬间','选择一件陪伴很久的物品，观察整体、磨损与细节。',['拍下整体','寻找磨损','留住细节']),('书本','书页里的时间','翻开一本旧书，找到阅读留下的印记。',['记录封面','寻找折角','靠近笔迹']),('杯子','一只杯子的日常','让熟悉的杯子成为今天的主角。',['观察杯形','捕捉杯沿','记录把手'])],
'window':[('窗边','光停下的地方','走到窗边，留意光与房间的交界。',['交代窗景','寻找亮面','记录暗部']),('植物','向光而生','观察一株植物怎样迎接窗外的光。',['记录姿态','观察叶缘','靠近新芽']),('光影','房间里的慢时光','观察自然光落在室内的痕迹。',['寻找光斑','记录边界','捕捉过渡'])],
'color':[('颜色','今天偏爱这一色','选一种沿路出现的颜色，用照片收集它。',['找到主色','记录呼应','寻找变化']),('门窗','街角的颜色','在公共道路上观察不同门窗的色彩。',['观察门面','寻找色块','靠近纹理']),('路边','一段温柔的散步','沿熟悉的路寻找平时忽略的小景。',['记录起点','发现亮色','留下终点'])],
'shadow':[('影子','影子的另一面','找到地面或墙面上的影子，观察它的轮廓。',['找到投影','观察边缘','记录交叠']),('树影','风写在墙上的诗','停在树荫旁，捕捉叶片投下的形状。',['观察树影','寻找疏密','记录留白']),('光影','光走过的路径','寻找阳光与阴影相遇的位置。',['记录明暗','寻找边界','捕捉形状'])],
'geometry':[('圆形','日常的圆周率','寻找身边的圆，观察轮廓与周围空间。',['寻找圆形','记录重复','观察局部']),('线条','城市的细线','在安全的人行区域寻找延伸的线条。',['寻找方向','记录交汇','留下终点']),('建筑','转角的秩序','观察建筑外立面的重复与变化。',['记录整体','寻找重复','观察转角'])],
'detail':[('纹理','触手可及的世界','靠近身边一种材料，观察它的表面。',['记录材料','寻找纹路','捕捉细节']),('叶片','一片叶子的风景','无需摘下叶子，用镜头发现细小的纹路。',['观察叶形','靠近叶脉','记录叶缘']),('织物','柔软的地形','铺开一块常用的织物，观察褶皱里的光。',['记录褶皱','寻找光面','靠近织纹'])]}
methods=['三格故事','单图配文','双图对照']
constraints=['同一位置','只拍细节','单一颜色','留出空白']
tasks=[]
for tid,title,subtitle,env in themes:
 for n in range(10):
  obj,name,summary,steps=subjects[tid][n%3]
  method=methods[n%3 if n<9 else 0]
  count={'单图配文':1,'双图对照':2,'三格故事':3}[method]
  constraint=constraints[(n//3)%4]
  if constraint=='只拍细节': steps=['靠近表面','发现痕迹','捕捉纹理']
  hints=[f'围绕「{obj}」{s}，{constraint}。调整距离，让主体清晰。' for s in steps[:count]]
  tasks.append(dict(id=f'{tid}-{n+1:02}',themeID=tid,title=name if n==0 else name+' · '+constraint,summary=summary+' '+('户外拍摄请留意道路安全，尊重他人隐私。' if env=='户外' else '不用布置完美场景，真实就很好。'),object=obj,method=method,constraint=constraint,environments=[env] if tid not in ['detail','geometry'] else ['室内','户外'],minutes={1:5,2:10,3:10 if n==0 else 20}[count],steps=steps[:count],hints=hints))
data=dict(schemaVersion=1,contentVersion=1,themes=[dict(id=i,title=t,subtitle=s,image='theme-'+i,environment=e) for i,t,s,e in themes],tasks=tasks)
(base/'Crailglitun/Resources/tasks.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
