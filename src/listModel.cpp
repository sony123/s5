#include "listModel.h"

ListModel::ListModel(ListItem *prototype, QObject *parent) :
    QAbstractListModel(parent), m_prototype(prototype)
{
    setRoleNames(m_prototype->roleNames());
}

int ListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_list.size();
}

QVariant ListModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= m_list.size())
        return QVariant();
    return m_list.at(index.row())->data(role);
}

ListModel::~ListModel() {
    delete m_prototype;
    clear();
}

void ListModel::appendRow(ListItem *item)
{
    appendRows(QList<ListItem*>() << item);
}

void ListModel::appendRows(const QList<ListItem *> &items)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount()+items.size()-1);
    foreach(ListItem *item, items) {
        connect(item, SIGNAL(dataChanged()), SLOT(handleItemChange()));
        m_list.append(item);
    }
    endInsertRows();
}

void ListModel::insertRow(int row, ListItem *item)
{
    beginInsertRows(QModelIndex(), row, row);
    connect(item, SIGNAL(dataChanged()), SLOT(handleItemChange()));
    m_list.insert(row, item);
    endInsertRows();
}

// Relay dataChange() signal from ListItem to view
void ListModel::handleItemChange()
{
#ifdef DBG
    qDebug() << "handleItemChange() slot";
#endif
    ListItem* item = static_cast<ListItem*>(sender());
    QModelIndex index = indexFromItem(item);
    if(index.isValid())
        emit dataChanged(index, index);
}

ListItem * ListModel::find(const QString &id) const
{
    foreach(ListItem* item, m_list) {
        if(item->name() == id) return item;
    }
    return 0;
}

QModelIndex ListModel::indexFromItem(const ListItem *item) const
{
    Q_ASSERT(item);
    for(int row=0; row<m_list.size(); ++row) {
        if(m_list.at(row) == item) return index(row);
    }
    return QModelIndex();
}

Q_INVOKABLE void ListModel::clear()
{
    qDeleteAll(m_list);
    m_list.clear();
    this->reset();
}

bool ListModel::removeRow(int row, const QModelIndex &parent)
{
    Q_UNUSED(parent);
    //  if(row < 0 || row >= m_list.size()) return false;
    if(row < 0 || row > m_list.size()) return false;
    beginRemoveRows(QModelIndex(), row, row);
    // Notify view
//    emit dataChanged(QModelIndex::child(row, 0), QModelIndex::child(row, 0));
    delete m_list.takeAt(row);
    endRemoveRows();
    return true;
}

bool ListModel::removeRows(int row, int count, const QModelIndex &parent)
{
    Q_UNUSED(parent);
//    if(row < 0 || (row+count) >= m_list.size()) return false;
    if(row < 0 || (row+count) > m_list.size()) return false;
    beginRemoveRows(QModelIndex(), row, row+count-1);
    for(int i=0; i<count; ++i) {
        // Notify view
//        emit dataChanged();
        delete m_list.takeAt(row);
    }
    endRemoveRows();
    return true;
}

ListItem * ListModel::takeRow(int row)
{
    beginRemoveRows(QModelIndex(), row, row);
    ListItem* item = m_list.takeAt(row);
    endRemoveRows();
    return item;
}

/*
bool ListModel::setItemData (const QModelIndex & index, const QMap<int, QVariant> & roles) {
    if (index.isValid()) {
        // TODO: Copy QMap values to ListItem
        QMapIterator<int, QVariant> i(roles);
        while (i.hasNext()) {
            i.next();
            //cout << i.key() << ": " << i.value() << endl;
        }

//        ListItem* item = new
//        m_list.replace(index.row(), item);
        emit dataChanged(index, index);
        return true;
    }
    else
        return false;
}
*/
